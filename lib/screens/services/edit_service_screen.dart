import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:intl/intl.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../providers/service/service_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/car_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/customTextField.dart';

class EditServiceScreen extends ConsumerStatefulWidget {
  final String serviceId;
  final String carId;
  const EditServiceScreen({
    super.key,
    required this.serviceId,
    required this.carId,
  });

  @override
  ConsumerState<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends ConsumerState<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _serviceNotesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _serviceCenterController =
      TextEditingController();

  String? _selectedCarId;

  DateTime? _selectedDate;
  XFile? _pickedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
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
    if (_pickedImage == null || _selectedCarId == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$userId/cars/$_selectedCarId/services/$serviceId/invoice.jpg',
      );

      await storageRef.putFile(File(_pickedImage!.path));
      return await storageRef.getDownloadURL();
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message:
            "Došlo je do greške prilikom spremanja računa. Pokušajte ponovo kasnije.",
      );
      return null;
    }
  }

  Future<void> _updateService(ServiceModel service) async {
    final currentUser = await ref.read(currentUserFutureProvider.future);
    final carProvider = ref.read(carServiceProvider)!;

    if (currentUser == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Korisnik nije pronađen.",
      );
      return;
    }

    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedCarId == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Molimo ispunite sva obavezna polja.",
      );
      return;
    }

    setState(() => _isLoading = true);
    String? invoiceUrl = service.invoiceUrl;
    if (_pickedImage != null) {
      invoiceUrl = await _uploadInvoice(widget.serviceId, currentUser.uid);
    }

    final mileageValue = int.tryParse(_mileageController.text.trim()) ??
        double.tryParse(
          _mileageController.text.trim().replaceAll(',', '.'),
        )?.toInt() ??
        0;
    final priceValue = double.tryParse(
          _priceController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    final updatedService = ServiceModel(
      id: widget.serviceId,
      carId: _selectedCarId!,
      type: _serviceTypeController.text.trim(),
      service_notes: _serviceNotesController.text.trim(),
      price: priceValue,
      mileage_at_service: mileageValue,
      service_center: _serviceCenterController.text.trim(),
      date: _selectedDate!,
      invoiceUrl: invoiceUrl,
    );

    final currentCar = await carProvider.getCarById(_selectedCarId!);
    if (currentCar != null && mileageValue > currentCar.mileage) {
      await carProvider.updateCarMileage(_selectedCarId!, mileageValue);
      ref.invalidate(carDetailsProvider(_selectedCarId!));
      ref.invalidate(carsProvider);
    }

    await ref.read(servicesServiceProvider)?.updateService(updatedService);

    setState(() => _isLoading = false);

    if (mounted) {
      CustomSnackbar.show(
        context,
        type: AlertType.success,
        title: "Uspjeh",
        message: "Podaci o servisu su uspješno ažurirani.",
      );
      ref.invalidate(
        serviceDetailsWithCarProvider((carId: widget.carId, serviceId: widget.serviceId)),
      );
      ref.invalidate(servicesForCarProvider(widget.carId));
      GoRouter.of(context).pop();
    } else {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message:
            "Došlo je do greške prilikom ažuriranja podataka o servisu. Pokušajte ponovo kasnije.",
      );
    }
  }

  void _populateFields(ServiceModel service) {
    _serviceTypeController.text = service.type;
    _serviceNotesController.text = service.service_notes;
    _priceController.text = service.price.toString();
    _mileageController.text = service.mileage_at_service.toString();
    _serviceCenterController.text = service.service_center;
    _selectedDate = service.date;
    _selectedCarId = service.carId;
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
    final serviceAsync = ref.watch(
      serviceDetailsWithCarProvider((carId: widget.carId, serviceId: widget.serviceId)),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: serviceAsync.when(
          data: (data) => data?.car?.brand ?? "Detalji servisa",
          loading: () => "Učitavanje...",
          error: (err, _) => "Greška",
        ),
        subtitle: serviceAsync.when(
          data: (data) =>
              data?.car != null ? "${data!.car.year} ${data.car.model}" : "",
          loading: () => "Učitavanje...",
          error: (err, _) => "",
        ),
      ),

      body: serviceAsync.when(
        data: (data) {
          if (data == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: CustomAlert(
                type: AlertType.error,
                title: "Greška",
                message: "Podaci o servisu nisu pronađeni.",
              ),
            );
          }

          _populateFields(data.service);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  _buildDatePicker(),
                  CustomTextField(
                    controller: _priceController,
                    label: 'Cijena servisa',
                    icon: 'material-symbols:attach-money-rounded',
                    hint: '250.50',
                    suffixText: "BAM",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                  ),
                  CustomTextField(
                    controller: _mileageController,
                    label: 'Kilometraža pri servisu',
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

                  _buildImagePicker(data.service.invoiceUrl),

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
                          outlined: true,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          onPressed: () {
                            _updateService(data.service);
                          },
                          text: 'Spremi',
                          icon: 'proicons:save',
                          isLoading: _isLoading,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: CustomAlert(
            type: AlertType.error,
            title: "Greška",
            message:
                "Došlo je do greške prilikom učitavanja podataka o servisu: $err",
          ),
        ),
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
                size: 20,
              ),
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
                  color: _selectedDate == null
                      ? Colors.grey[500]
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(String? existingUrl) {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: const [
              IconifyIcon(
                icon: 'jam:picture-edit',
                color: Color(0xFF4E4E4E),
                size: 15,
              ),
              SizedBox(width: 8),
              Text(
                'Slika računa',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E4E4E),
                  fontSize: 14,
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
                          'Odaberi sliku računa',
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
}
