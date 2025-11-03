import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:motus/widgets/customAppBar.dart';
import '../../models/car_model.dart';
import '../../providers/car_provider.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/customTextField.dart';

class AddCarScreen extends ConsumerStatefulWidget {
  const AddCarScreen({super.key});

  @override
  ConsumerState<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends ConsumerState<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _displacementController = TextEditingController();
  final TextEditingController _horsepowerController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedDriveType;
  String? _selectedVehicleType;
  XFile? _pickedImage;

  bool _isLoading = false;

  final List<String> _fuelTypes = ['Benzin', 'Dizel', 'Električni', 'Hibrid'];
  final List<String> _transmissions = ['Automatski', 'Manualni'];
  final List<String> _driveTypes = ['Prednji pogon', 'Zadnji pogon', '4x4'];
  final List<String> _vehicle_types = ['Karavan', 'Sedan', 'SUV', 'Hatchback', 'Kabriolet', 'Pickup', 'Monovolumen', 'Coupe', 'VAN', 'Ostalo'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<String?> _uploadImage(String carId) async {
    if (_pickedImage == null) return null;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("Korisnik nije prijavljen.");

      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$userId/cars/$carId/image.jpg');

      await ref.putFile(File(_pickedImage!.path));
      return await ref.getDownloadURL();
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Došlo je do greške prilikom slanja slike. Pokušajte ponovo kasnije.",
      );
      return null;
    }
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFuelType == null || _selectedTransmission == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.warning,
        title: "Upozorenje",
        message: "Molimo odaberite tip goriva i/ili vrstu mjenjača.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final carService = ref.read(carServiceProvider)!;

      final tempCar = CarModel(
        id: '',
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        fuel_type: _selectedFuelType!,
        transmission: _selectedTransmission!,
        drive_type: _selectedDriveType!,
        vehicle_type: _selectedVehicleType!,
        displacement: double.tryParse(_displacementController.text.trim()) ?? 0.0,
        horsepower: int.tryParse(_horsepowerController.text.trim()) ?? 0,
        license_plate: _licensePlateController.text.trim(),
        mileage: int.tryParse(_mileageController.text.trim()) ?? 0,
        vin: _vinController.text.trim(),
      );

      final docRef = await carService.addCar(tempCar);

      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(docRef.id);
      }

      if (imageUrl != null) {
        final updatedCar = tempCar.copyWith(id: docRef.id, imageUrl: imageUrl);
        await carService.updateCar(docRef.id, updatedCar);
      }

      if (mounted) {
        CustomSnackbar.show(
          context,
          type: AlertType.success,
          title: "Uspješno",
          message: "Vozilo je uspješno dodano u bazu podataka.",
        );
        ref.invalidate(carsProvider);
        GoRouter.of(context).pop();
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Došlo je do greške prilikom spremanja vozila. Pokušajte ponovo kasnije.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _displacementController.dispose();
    _horsepowerController.dispose();
    _licensePlateController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dodaj vozilo',
        showAddCarButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _brandController,
                label: 'Marka vozila',
                icon: 'tabler:brand-days-counter',
                hint: 'Volkswagen',
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              CustomTextField(
                controller: _modelController,
                label: 'Model vozila',
                icon: 'ph:steering-wheel-bold',
                hint: 'Golf 7',
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              CustomTextField(
                controller: _yearController,
                label: 'Godina',
                icon: 'solar:calendar-broken',
                hint: '2018',
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              CustomTextField(
                controller: _vinController,
                label: 'VIN',
                icon: 'mdi:letters',
                hint: 'VW82HDB3IDN3H3G',
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              CustomTextField(
                controller: _licensePlateController,
                label: 'Registracija',
                icon: 'solar:plate-broken',
                hint: 'T05-E-371',
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              CustomTextField(
                controller: _displacementController,
                label: 'Zapremina motora (ccm)',
                icon: 'mdi:engine-outline',
                hint: '1600',
                suffixText: "CCM",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              CustomTextField(
                controller: _horsepowerController,
                label: 'Snaga',
                icon: 'streamline-ultimate:car-engine-11',
                hint: '105',
                suffixText: "KS",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              CustomTextField(
                controller: _mileageController,
                label: 'Kilometraža',
                icon: 'stash:data-numbers',
                hint: '182 440',
                suffixText: "KM",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                'Pogon',
                'mingcute:four-wheel-drive-line',
                _driveTypes,
                _selectedDriveType,
                    (val) => setState(() => _selectedDriveType = val),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                'Tip goriva',
                'hugeicons:fuel-station',
                _fuelTypes,
                _selectedFuelType,
                    (val) => setState(() => _selectedFuelType = val),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                'Mjenjač',
                'fluent:transmission-20-regular',
                _transmissions,
                _selectedTransmission,
                    (val) => setState(() => _selectedTransmission = val),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                'Vrsta vozila',
                'ion:car-sport-outline',
                _vehicle_types,
                _selectedVehicleType,
                    (val) => setState(() => _selectedVehicleType = val),
              ),
              const SizedBox(height: 15),
              _buildImagePicker(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () => GoRouter.of(context).pop(),
                      text: 'Odustani',
                      icon: 'eva:close-circle-outline',
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      letterSpacing: 3,
                      borderRadius: 5.0,
                      outlined: true,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      onPressed: _saveCar,
                      text: 'Spremi',
                      icon: 'proicons:save',
                      isLoading: _isLoading,
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconifyIcon(icon: 'jam:picture-edit', color: Color(0xFF4E4E4E), size: 15),
              const SizedBox(width: 6),
              const Text(
                'Slika vozila',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4E4E4E), fontSize: 15),
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
            child: _pickedImage == null
                ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconifyIcon(icon: 'jam:picture-edit', size: 30, color: Colors.grey),
                SizedBox(height: 10),
                Text('Odaberi sliku vozila', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_pickedImage!.path),
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

  Widget _buildDropdown(
      String label,
      String icon,
      List<String> items,
      String? selectedValue,
      ValueChanged<String?> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconifyIcon(icon: icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E4E4E),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFEDEDED), width: 1.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                onChanged: onChanged,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                hint: Text(
                  'Odaberite ${label.toLowerCase()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                style: const TextStyle(color: Color(0xFF4E4E4E)),
                dropdownColor: const Color(0xFFF9F9F9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
