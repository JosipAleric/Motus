import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motus/models/user_model.dart';
import 'package:motus/widgets/customAppBar.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:motus/widgets/customButton.dart';

import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/customAlert.dart';
import '../widgets/customSnackbar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  String? _selectedLanguage;
  String? _selectedCurrency;
  bool _initialized = false;

  Future<void> _saveSettings(UserModel currentUser) async {
    setState(() => _isLoading = true);
    final userService = ref.read(firestoreServiceProvider);

    final updatedUser = currentUser.copyWith(
      preferredLanguage: _selectedLanguage?.toLowerCase(),
      preferredCurrency: _selectedCurrency?.toLowerCase(),
    );

    try {
      await userService.saveUser(updatedUser);
      CustomSnackbar.show(
        context,
        type: AlertType.success,
        title: "Uspješno",
        message: "Vaše postavke su uspješno ažurirane.",
      );
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message:
            "Došlo je do greške prilikom ažuriranja podataka. Pokušajte ponovo kasnije.",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Greška pri učitavanju korisnika: $e')),
      ),
      data: (currentUser) {
        if (!_initialized) {
          _selectedLanguage = currentUser?.preferredLanguage ?? 'hrv';
          _selectedCurrency = currentUser?.preferredCurrency ?? 'eur';
          _initialized = true;
        }

        return Scaffold(
          appBar: const CustomAppBar(title: 'Postavke'),
          body: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: IconifyIcon(
                        icon: 'icon-park-outline:right',
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Preferirani jezik',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontFamily: "MPlus1",
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 0),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildLanguageCard('Hrvatski (HRV)', 'hrv'),
                const SizedBox(height: 10),
                _buildLanguageCard('Engleski (ENG)', 'eng'),
                const SizedBox(height: 15),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: IconifyIcon(
                        icon: 'icon-park-outline:right',
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Preferirana valuta',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontFamily: "MPlus1",
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 0),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCurrencyCard('Euro (EUR)', 'lucide:euro', 'eur'),
                const SizedBox(height: 10),
                _buildCurrencyCard(
                  'Američki Dolar (USD)',
                  'healthicons:dollar',
                  'usd',
                ),
                const SizedBox(height: 10),
                _buildCurrencyCard(
                  'Konvertibilna Marka (BAM)',
                  'hugeicons:money-not-found-02',
                  'bam',
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "Spremi promjene",
                    isLoading: _isLoading,
                    onPressed: () {
                      if (!_isLoading) {
                        _saveSettings(currentUser!);
                      }
                    },
                    icon: "proicons:save",
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard(String languageName, String languageCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          onTap: () {
            setState(() {
              _selectedLanguage = languageCode;
            });
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          title: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage(
                  languageCode == 'hrv'
                      ? 'assets/images/flags/croatia.png'
                      : 'assets/images/flags/uk.png',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                languageName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Radio<String>(
            value: languageCode,
            groupValue: _selectedLanguage,
            onChanged: (String? value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(
    String currencyName,
    String icon,
    String currencyCode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          onTap: () {
            setState(() {
              _selectedCurrency = currencyCode;
            });
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          title: Row(
            children: [
              IconifyIcon(icon: icon, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Text(
                currencyName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Radio<String>(
            value: currencyCode,
            groupValue: _selectedCurrency,
            onChanged: (String? value) {
              setState(() {
                _selectedCurrency = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
