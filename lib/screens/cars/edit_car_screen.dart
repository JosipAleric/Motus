import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:motus/widgets/customAppBar.dart';
import '../../models/car_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/car_provider.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/customTextField.dart';

class EditCarScreen extends ConsumerStatefulWidget {
  final String carId;

  const EditCarScreen({super.key, required this.carId});

  @override
  ConsumerState<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends ConsumerState<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _displacementController = TextEditingController();
  final _horsepowerController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _mileageController = TextEditingController();
  final _vinController = TextEditingController();

  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedDriveType;
  String? _selectedVehicleType;
  XFile? _pickedImage;

  bool _isLoading = false;
  bool _initialized = false;

  final List<String> _fuelTypes = ['Benzin', 'Dizel', 'Električni', 'Hibrid'];
  final List<String> _transmissions = ['Automatski', 'Manualni'];
  final List<String> _driveTypes = ['Prednji pogon', 'Zadnji pogon', '4x4'];
  final List<String> _vehicleTypes = [
    'Karavan',
    'Sedan',
    'SUV',
    'Hatchback',
    'Kabriolet',
    'Pickup',
    'Monovolumen',
    'Coupe',
    'VAN',
    'Ostalo',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<String?> _uploadImage(String carId, String userId) async {
    if (_pickedImage == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$userId/cars/$carId/image.jpg',
      );
      await storageRef.putFile(File(_pickedImage!.path));
      return await storageRef.getDownloadURL();
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message:
            "Došlo je do greške prilikom slanja slike. Pokušajte ponovo kasnije.",
      );
      return null;
    }
  }

  Future<void> _updateCar(UserModel currentUser, CarModel existingCar) async {
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
      final carProvider = ref.read(carServiceProvider)!;

      String? imageUrl = existingCar.imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(existingCar.id, currentUser.uid);
      }

      final updatedCar = existingCar.copyWith(
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        fuel_type: _selectedFuelType!,
        transmission: _selectedTransmission!,
        drive_type: _selectedDriveType!,
        displacement:
            double.tryParse(
              _displacementController.text.trim().replaceAll(',', '.'),
            ) ??
            0.0,
        horsepower: int.tryParse(_horsepowerController.text.trim()) ?? 0,
        license_plate: _licensePlateController.text.trim(),
        mileage:
            int.tryParse(_mileageController.text.trim()) ??
            double.tryParse(
              _mileageController.text.trim().replaceAll(',', '.'),
            )?.toInt() ??
            0,
        vin: _vinController.text.trim(),
        imageUrl: imageUrl,
        vehicle_type: _selectedVehicleType!,
      );

      await carProvider.updateCar(existingCar.id, updatedCar);

      if (mounted) {
        CustomSnackbar.show(
          context,
          type: AlertType.success,
          title: "Uspješno",
          message: "Vozilo je uspješno ažurirano.",
        );
        ref.invalidate(carsProvider);
        ref.invalidate(carDetailsProvider(existingCar.id));
        GoRouter.of(context).pop();
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Došlo je do greške prilikom ažuriranja vozila.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFields(CarModel car) {
    if (_initialized) return;

    _brandController.text = car.brand;
    _modelController.text = car.model;
    _yearController.text = car.year.toString();
    _displacementController.text = car.displacement.toString();
    _horsepowerController.text = car.horsepower.toString();
    _licensePlateController.text = car.license_plate;
    _mileageController.text = car.mileage.toString();
    _vinController.text = car.vin;

    _fuelTypes.contains(car.fuel_type)
        ? _selectedFuelType = car.fuel_type
        : _selectedFuelType = null;
    _transmissions.contains(car.transmission)
        ? _selectedTransmission = car.transmission
        : _selectedTransmission = null;
    _driveTypes.contains(car.drive_type)
        ? _selectedDriveType = car.drive_type
        : _selectedDriveType = null;
    _vehicleTypes.contains(car.vehicle_type)
        ? _selectedVehicleType = car.vehicle_type
        : _selectedVehicleType = null;

    _initialized = true;
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
    final currentUserAsync = ref.watch(currentUserFutureProvider);
    final carAsync = ref.watch(carDetailsProvider(widget.carId));

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: Text('Korisnik nije prijavljen.')),
          );
        }

        return carAsync.when(
          data: (car) {
            if (car == null) {
              return const Scaffold(
                body: Center(child: Text('Vozilo nije pronađeno.')),
              );
            }

            _populateFields(car);

            return Scaffold(
              appBar: const CustomAppBar(
                title: 'Uredi vozilo',
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
                        hint: 'Golf 7 Variant',
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
                        hint: '182440',
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
                        'fluent:transmission-20-regular',
                        _vehicleTypes,
                        _selectedVehicleType,
                        (val) => setState(() => _selectedVehicleType = val),
                      ),
                      const SizedBox(height: 15),
                      _buildImagePicker(car.imageUrl),
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
                              onPressed: () => _updateCar(currentUser, car),
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
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) =>
              Scaffold(body: Center(child: Text('Greška: $err'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Greška: $err'))),
    );
  }

  Widget _buildImagePicker(String? existingUrl) {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              IconifyIcon(
                icon: 'jam:picture-edit',
                color: Color(0xFF4E4E4E),
                size: 17,
              ),
              SizedBox(width: 4),
              Text(
                'Slika vozila',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E4E4E),
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
            child: _pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : existingUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(existingUrl, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconifyIcon(
                          icon: 'jam:picture-edit',
                          size: 30,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Odaberi sliku vozila',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
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
