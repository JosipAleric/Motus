import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:motus/theme/app_theme.dart';
import 'package:motus/widgets/customAppBar.dart';
import 'package:motus/widgets/customButton.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:motus/widgets/customSnackbar.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customTextField.dart';
import 'package:intl/intl.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _selectedDate;

  void _navigateAndClose(route) {
    GoRouter.of(context).pop();
    GoRouter.of(context).go(route);
  }

  Future<void> _signOut() async {
    await AuthService().logout();
    GoRouter.of(context).go('/login');
  }

  Future<void> _saveUser() async {
    setState(() {
      _isLoading = true;
    });
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    try {
      final updatedUser = user.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        dateOfBirth: _selectedDate,
      );

      await ref.read(firestoreServiceProvider).saveUser(updatedUser);

      CustomSnackbar.show(
        context,
        type: AlertType.success,
        title: "Uspjeh",
        message: "Podaci su uspješno ažurirani.",
      );
      setState(() {
        _isEditing = false;
      });
      ref.invalidate(currentUserStreamProvider);
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Došlo je do greške prilikom spremanja podataka: $e",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields(user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _selectedDate = user.dateOfBirth ?? null;
    _phoneController.text = user.phone ?? '';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              dividerColor: AppColors.divider,
              backgroundColor: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
        _selectedDate = picked;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    return Scaffold(
      appBar: CustomAppBar(title: 'Detalji o profilu'),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CustomAlert(
                type: AlertType.error,
                title: "Greška",
                message: "Korisnik nije pronađen u bazi podataka.",
              ),
            );
          }
          _populateFields(user);
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(45),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textSecondary,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : ''}${user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : ''}',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: "Michroma",
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              user.email,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: 140,
                              child: CustomButton(
                                isLoading: _isLoading,
                                text: _isEditing ? 'Odustani' : 'Uredi profil',
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 0,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = !_isEditing;
                                  });
                                },
                                icon: _isEditing ? 'material-symbols:cancel-outline-rounded' : 'mynaui:edit-one-solid',
                                iconSize: 16,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Divider(color: AppColors.divider),
                    ),

                    CustomTextField(
                      disabled: !_isEditing,
                      controller: _firstNameController,
                      label: 'Ime',
                      icon: 'solar:user-broken',
                      validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                    ),

                    CustomTextField(
                      disabled: !_isEditing,
                      controller: _lastNameController,
                      label: 'Prezime',
                      icon: 'fluent:rename-a-20-regular',
                      validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                    ),

                    CustomTextField(
                      disabled: !_isEditing,
                      controller: _emailController,
                      label: 'Email adresa',
                      icon: 'mage:email',
                      hint: 'Zamijenjeno ulje i filteri...',
                    ),

                    CustomTextField(
                      disabled: !_isEditing,
                      controller: _phoneController,
                      label: 'Broj mobitela',
                      icon: 'ph:phone-list',
                      keyboardType: TextInputType.number,
                      hint: "Unesite broj mobitela",
                    ),

                    _buildDatePicker(disabled: !_isEditing),


                    _isEditing ? Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: CustomButton(
                        isLoading: _isLoading,
                        text: "Spremi promjene",
                        color: Color(0xFF66CC8A),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 0,
                        ),
                        onPressed: () {
                          _saveUser();
                        },
                        icon: _isEditing ? 'lets-icons:save-fill' : 'mynaui:edit-one-solid',
                        iconSize: 20,
                      ),
                    ) : const SizedBox(height: 5),

                    const Divider(color: AppColors.divider),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF22727).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconifyIcon(
                          icon: "mdi:logout",
                          size: 17,
                          color:  const Color(0xFFF22727),
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Odjava',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF22727),
                              letterSpacing: 1.2,
                            ),
                          ),
                          IconifyIcon(
                            icon: "mdi:chevron-right",
                            color: const Color(0xFFF22727,)
                          ),
                        ],
                      ),
                      onTap: () => _signOut(),
                    ),


                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDatePicker({bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconifyIcon(
                icon: 'lets-icons:date-range-light',
                color: AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Datum rođenja',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: disabled,
            child: GestureDetector(
              onTap: disabled ? null : _pickDate,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFFEDEDED),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedDate == null
                      ? 'Odaberite datum'
                      : DateFormat('dd.MM.yyyy.').format(_selectedDate!),
                  style: TextStyle(
                    fontSize: 13,
                    color: disabled ? Colors.grey[500] : (_selectedDate == null ? Colors.grey[500] : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
