import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:motus/screens/cars/add_car_screen.dart';
import 'package:motus/screens/cars/car_details_screen.dart';
import 'package:motus/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motus/widgets/customDrawer.dart';
import 'firebase_options.dart';

// Screens
import 'screens/services/services_screen.dart';
import 'screens/services/service_details_screen.dart';
import 'screens/services/add_service_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

import 'widgets/customBottomNav.dart';
import 'providers/user_provider.dart';

final drawerProvider = StateProvider<Function?>((ref) => null);

/// Pomoćna klasa koja obavještava GoRouter kada se tok promijeni
/// (u ovom slučaju, kada se promijeni stanje autentifikacije)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    // Koristi se asBroadcastStream() da ne bi utjecao na originalni stream
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Instanca GoRoutera, statična i definirana izvan build metode.
// To sprječava rekreaciju navigacijskog stoga pri Hot Reloada.
final _router = GoRouter(
  initialLocation: '/',
  // Koristi se za automatsko osvježavanje ruta kada se promijeni stanje auth-a
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  routes: [
    // Rute bez Shell-a (autentifikacija)
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // Rute sa Shell-om (glavni dio aplikacije s navigacijskom trakom)
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (_, __) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'car_details/:carId',
              name: 'car_details',
              builder: (_, state) {
                final carId = state.pathParameters['carId']!;
                return CarDetailsScreen(carId: carId);
              },
            ),
            GoRoute(
              path: '/add_car',
              name: 'add_car',
              builder: (_, __) => const AddCarScreen())
          ],
        ),
        GoRoute(
          path: '/services',
          name: 'services',
          builder: (_, __) => const ServicesScreen(),
          routes: [
            GoRoute(
              path: 'details/:serviceId/:carId',
              name: 'service_details',
              builder: (_, state) {
                final serviceId = state.pathParameters['serviceId']!;
                final carId = state.pathParameters['carId']!;
                return ServiceDetailsScreen(
                  serviceId: serviceId,
                  carId: carId,
                );
              },
            ),
          ],
        ),
        GoRoute(path: '/fuel', name: 'fuel', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/profile', name: 'profile', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/add_service', name: 'add_service', builder: (_, __) => const AddServiceScreen()),
      ],
    ),
  ],
  // Logika preusmjeravanja sada koristi ProviderScope za čitanje stanja korisnika
  redirect: (context, state) {
    // Čitanje stanja iz Riverpod ProviderScope-a
    final userAsyncValue = ProviderScope.containerOf(context).read(authStateChangesProvider);
    final user = userAsyncValue.value;

    // Ako se stanje još uvijek učitava, ne preusmjeravaj
    if (userAsyncValue.isLoading) return null;

    final loggedIn = user != null;
    final loggingIn = state.uri.toString() == '/login' || state.uri.toString() == '/register';

    // Ako korisnik nije logiran i pokušava pristupiti zaštićenoj ruti, idi na login
    if (!loggedIn && !loggingIn) return '/login';

    // Ako je korisnik logiran i pokušava pristupiti login/register stranici, idi na početnu
    if (loggedIn && loggingIn) return '/';

    return null;
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(authStateChangesProvider);

    if (asyncUser.isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Motus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 12.0),
          bodyMedium: TextStyle(fontSize: 12.0),
          bodySmall: TextStyle(fontSize: 12.0),
        ),
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: const Color(0xFF1B1B1B),
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

int getTabIndexFromLocation(String location) {
  final tabRoutes = {
    0: ['/'],
    1: ['/services'],
    3: ['/fuel'],
    4: ['/profile'],
  };
  for (var entry in tabRoutes.entries) {
    for (var root in entry.value) {
      if (location.startsWith(root) && location.length > root.length) continue;
      if (location == root) return entry.key;
    }
    if (location.startsWith(entry.value[0])) return entry.key;
  }
  return 0;
}

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _updateSelectedIndex() {
    final location = GoRouter.of(context).routeInformationProvider.value.location ?? '/';
    final newIndex = getTabIndexFromLocation(location);
    if (_selectedIndex != newIndex) setState(() => _selectedIndex = newIndex);
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      GoRouter.of(context).push('/add_service');
      return;
    }
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/services');
        break;
      case 3:
        GoRouter.of(context).go('/fuel');
        break;
      case 4:
        GoRouter.of(context).go('/profile');
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Odmah ažuriraj index kad se ovisnosti promijene (uključujući navigaciju)
    _updateSelectedIndex();
  }

  @override
  void initState() {
    super.initState();
    // Registracija callback funkcije za drawer, SAMO JEDNOM
    // OVO JE SIGURNO JER SE POZIVA PRIJE PRVOG BUILD-A
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(drawerProvider.notifier).state = openDrawer;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: widget.child,
      bottomNavigationBar: CustomBottomNav(onItemTapped: _onItemTapped),
    );
  }
}