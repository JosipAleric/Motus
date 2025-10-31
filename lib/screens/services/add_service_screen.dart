// add_service_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../../models/car_model.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../providers/service/service_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/car_provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/customTextField.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _serviceNotesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _serviceCenterController = TextEditingController();

  String? _selectedCarId;

  DateTime? _selectedDate;
  XFile? _pickedInvoice;
  bool _isLoading = false;

  Future<void> _pickInvoice() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedInvoice = image);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<String?> _uploadInvoice(String serviceId, String userId) async {
    if (_pickedInvoice == null || _selectedCarId == null) return null;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/$userId/cars/$_selectedCarId/services/$serviceId/invoice.jpg');

      await storageRef.putFile(File(_pickedInvoice!.path));
      return await storageRef.getDownloadURL();
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Došlo je do greške. Pokušajte ponovo kasnije.",
      );
      return null;
    }
  }

  Future<void> _saveService(UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.warning,
        title: "Upozorenje",
        message: "Odaberite datum servisa.",
      );
      return;
    }
    if (_selectedCarId == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.warning,
        title: "Upozorenje",
        message: "Odaberite automobil za servis.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final servicesProvider = ref.read(servicesServiceProvider)!;
      final carProvider = ref.read(carServiceProvider)!;

      final double priceValue = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final int mileageValue = int.tryParse(_mileageController.text.trim()) ?? 0;

      final tempService = ServiceModel(
        id: '',
        carId: _selectedCarId!,
        type: _serviceTypeController.text.trim(),
        service_notes: _serviceNotesController.text.trim(),
        price: priceValue,
        date: _selectedDate!,
        mileage_at_service: mileageValue,
        service_center: _serviceCenterController.text.trim(),
        invoiceUrl: null,
      );

      if (servicesProvider != null) {
        final docRef = await servicesProvider.addService(_selectedCarId!, tempService);

        String? invoiceUrl;

        if (_pickedInvoice != null) {
          invoiceUrl = await _uploadInvoice(docRef.id, currentUser.uid);
        }

        if (invoiceUrl != null) {
          final updatedService = tempService.copyWith(id: docRef.id, invoiceUrl: invoiceUrl);
          await servicesProvider.updateService(_selectedCarId!, docRef.id, updatedService);
        }

        final currentCar = await carProvider.getCarById(_selectedCarId!);
        if (currentCar != null && mileageValue > currentCar.mileage) {
          await carProvider.updateCarMileage(_selectedCarId!, mileageValue);
          ref.invalidate(carDetailsProvider(_selectedCarId!));
          ref.invalidate(carsProvider);
        }

        if (mounted) {
          CustomSnackbar.show(
            context,
            type: AlertType.success,
            title: "Uspješno",
            message: "Servis je uspješno dodan.",
          );
          ref.invalidate(servicesPaginatorProvider(_selectedCarId!));
          ref.invalidate(latestServicesWithCarProvider);
          ref.invalidate(lastServiceForCarProvider(_selectedCarId!));
          GoRouter.of(context).pop();
        }
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Došlo je do greške prilikom spremanja servisa. Pokušajte ponovo kasnije.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _serviceTypeController.dispose();
    _serviceNotesController.dispose();
    _priceController.dispose();
    _mileageController.dispose();
    _serviceCenterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserFutureProvider);
    final carsAsync = ref.watch(carsProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            appBar: CustomAppBar(title: 'Greška',),
            body: Center(child: Text('Korisnik nije logiran.')),
          );
        }

        if(carsAsync.asData?.value.isEmpty ?? true) {
          return Scaffold(
            appBar: const CustomAppBar(
              title: 'Dodaj servis',
            ),
            body: const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: const CustomAlert(
                type: AlertType.warning,
                title: "Nema dostupnih vozila",
                message: "Greška kod dohvata automobila. Provjerite imate li dodanih automobila ili pokušajte ponovo kasnije.",
              ),
            ),
          );
        }

        return Scaffold(
          appBar: const CustomAppBar(
            title: 'Dodaj servis',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCarDropdown(carsAsync),
                  const SizedBox(height: 5),
                  CustomTextField(
                    controller: _serviceTypeController,
                    label: 'Tip servisa',
                    icon: 'tabler:file-description-filled',
                    hint: 'Zamjena ulja i filtera zraka, klime...',
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                  ),

                  CustomTextField(
                    controller: _serviceCenterController,
                    label: 'Servisni centar',
                    icon: 'qlementine-icons:rename-16',
                    hint: 'AC Star, Euro servis...',
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                  ),

                  // Odabir datuma
                  _buildDatePicker(),

                  CustomTextField(
                    controller: _priceController,
                    label: 'Cijena servisa',
                    icon: 'material-symbols:attach-money-rounded',
                    hint: '250.50',
                    suffixText: "BAM",
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                  ),

                  CustomTextField(
                    controller: _mileageController,
                    label: 'Kilometraža (pri servisu)',
                    icon: 'stash:data-numbers',
                    hint: '195000',
                    suffixText: "KM",
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                  ),

                  CustomTextField(
                    controller: _serviceNotesController,
                    label: 'Dodatne napomene',
                    icon: 'hugeicons:note',
                    hint: 'Zamijenjeno ulje i filteri...',
                  ),

                  const SizedBox(height: 15),
                  _buildInvoicePicker(),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          onPressed: () => {
                            GoRouter.of(context).pop()
                          },
                          text: 'Odustani',
                          icon: 'eva:close-circle-outline',
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          letterSpacing: 3,
                          borderRadius: 5.0,
                          outlined: true,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: CustomButton(
                          onPressed:  () => _saveService(currentUser),
                          text: 'Spremi',
                          icon: 'proicons:save',
                          isLoading: _isLoading,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          letterSpacing: 3,
                          borderRadius: 5.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Greška pri učitavanju')),
        body: Center(child: Text('Došlo je do greške: $err')),
      ),
    );
  }

  Widget _buildCarDropdown(AsyncValue<List<CarModel>> carsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconifyIcon(icon: 'ion:car-sport-sharp', color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Odaberite vozilo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          carsAsync.when(
            data: (cars) {
              if (cars.isEmpty) {
                return const Text('Nema dodanih vozila.');
              }
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFFEDEDED), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCarId,
                    isExpanded: true,
                    onChanged: (String? newId) {
                      setState(() {
                        _selectedCarId = newId;
                      });
                    },
                    items: cars.map<DropdownMenuItem<String>>((CarModel car) {
                      return DropdownMenuItem<String>(
                        value: car.id,
                        child: Text('${car.brand} ${car.model} (${car.license_plate})'),
                      );
                    }).toList(),
                    hint: const Text(
                      'Odaberite automobil',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    dropdownColor: const Color(0xFFF9F9F9),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Greška pri učitavanju vozila: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
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
                  size: 20),
              const SizedBox(width: 8),
              const Text(
                'Datum servisa',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10.0),
                // border:
                // BorderSide(color: const Color(0xFFEDEDED), width: 1.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDate == null
                    ? 'Odaberite datum'
                    : DateFormat('dd.MM.yyyy.').format(_selectedDate!),
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedDate == null ? Colors.grey[500] :  AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget za odabir fakture (ostaje isti)
  Widget _buildInvoicePicker() {
    return GestureDetector(
      onTap: _pickInvoice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconifyIcon(
                icon: 'ion:receipt-outline',
                color: AppColors.textPrimary,
                size: 17,
              ),
              const SizedBox(width: 4),
              const Text(
                'Faktura/Račun',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: const Color(0xFFF9F9F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _pickedInvoice == null
                ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconifyIcon(
                  icon: 'ri:bill-line',
                  size: 30,
                  color: Colors.grey,
                ),
                const SizedBox(height: 10),
                Text(
                  'Odaberi sliku fakture (opcionalno)',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_pickedInvoice!.path),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}