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
  final TextEditingController _engineCapacityController =TextEditingController();
  final TextEditingController _horsepowerController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedDriveType;
  XFile? _pickedImage;

  bool _isLoading = false;

  final List<String> _fuelTypes = ['Benzin', 'Dizel', 'Električni', 'Hibrid'];
  final List<String> _transmissions = ['Automatski', 'Manualni'];
  final List<String> _driveTypes = ['Prednji pogon', 'Zadnji pogon', '4x4'];

  // Odabir slike
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  // Upload slike na Firebase Storage
  Future<String?> _uploadImage(String carId, String userId) async {
    if (_pickedImage == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('users/$userId/cars/$carId/image.jpg');

      await storageRef.putFile(File(_pickedImage!.path));
      return await storageRef.getDownloadURL();
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

  Future<void> _saveCar(UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFuelType == null || _selectedTransmission == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.warning,
        title: "Upozorenje",
        message: "Molimo odaberite tip goriva i mjenjač.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final carProvider = ref.read(carServiceProvider);

      final tempCar = CarModel(
        id: '',
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        fuel_type: _selectedFuelType!,
        transmission: _selectedTransmission!,
        displacement: _displacementController.text.trim(),
        engine_capacity:
            double.tryParse(_engineCapacityController.text.trim()) ?? 0.0,
        horsepower: int.tryParse(_horsepowerController.text.trim()) ?? 0,
        license_plate: _licensePlateController.text.trim(),
        mileage: int.tryParse(_mileageController.text.trim()) ?? 0,
        VIN: _vinController.text.trim(),
      );

      final docRef = await carProvider.addCar(currentUser.uid, tempCar);

      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(docRef.id, currentUser.uid);
      }

      if (imageUrl != null) {
        final updatedCar = tempCar.copyWith(id: docRef.id, imageUrl: imageUrl);
        await carProvider.updateCar(currentUser.uid, docRef.id, updatedCar);
      }

      if(mounted){
        CustomSnackbar.show(
          context,
          type: AlertType.success,
          title: "Uspjeh",
          message: "Vozilo je uspješno dodano.",
        );
        ref.invalidate(carsProvider);
        GoRouter.of(context).pop();
      }

    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message:
            "Došlo je do greške prilikom spremanja vozila. Pokušajte ponovo kasnije.",
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
    _engineCapacityController.dispose();
    _horsepowerController.dispose();
    _licensePlateController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserFutureProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Greška')),
            body: Center(
              child: Text(
                'Korisnik nije logiran. Možda je potrebno prijaviti se.',
              ),
            ),
          );
        }

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
                    controller: _engineCapacityController,
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
                          onPressed: () => _saveCar(currentUser),
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
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Greška pri učitavanju')),
        body: Center(child: Text('Došlo je do greške: $err')),
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
              IconifyIcon(
                icon: 'jam:picture-edit',
                color: Color(0xFF4E4E4E),
                size: 17,
              ),
              const SizedBox(width: 4),
              Text(
                'Slika vozila',
                style: const TextStyle(
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
              border: Border.all(color: Color(0xFFF9F9F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _pickedImage == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const IconifyIcon(
                        icon: 'jam:picture-edit',
                        size: 30,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Odaberi sliku vozila',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
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
                // Match the text style to the TextFormField's hint style when no value is selected
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
