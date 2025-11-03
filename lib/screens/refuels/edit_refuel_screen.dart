import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconify_design/iconify_design.dart';
import '../../models/refuel_model.dart';
import '../../providers/car_provider.dart';
import '../../providers/refuel/refuel_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/customTextField.dart';

class EditRefuelScreen extends ConsumerStatefulWidget {
  final String refuelId;
  final String carId;

  const EditRefuelScreen({
    super.key,
    required this.refuelId,
    required this.carId,
  });

  @override
  ConsumerState<EditRefuelScreen> createState() => _EditRefuelScreenState();
}

class _EditRefuelScreenState extends ConsumerState<EditRefuelScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _gasStationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  bool _usedAditives = false;
  bool _isSaving = false;

  void _populateFields(RefuelModel refuel) {
    _selectedDate = refuel.date;
    _mileageController.text = refuel.mileageAtRefuel.toString();
    _litersController.text = refuel.liters.toString();
    _priceController.text = refuel.price.toString();
    _gasStationController.text = refuel.gasStation ?? "";
    _notesController.text = refuel.notes ?? "";
    _usedAditives = refuel.usedFuelAditives;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save(RefuelModel original) async {
    final currentUser = await ref.read(currentUserFutureProvider.future);
    final carProvider = ref.read(carServiceProvider)!;
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Molimo ispunite sva obavezna polja.",
      );
      return;
    }

    setState(() => _isSaving = true);

    final liters = double.tryParse(_litersController.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final mileageValue = int.tryParse(_mileageController.text.trim()) ??
        double.tryParse(
          _mileageController.text.trim().replaceAll(',', '.'),
        )?.toInt() ??
        0;

    final updated = RefuelModel(
      id: original.id,
      carId: original.carId,
      date: _selectedDate!,
      mileageAtRefuel: mileageValue,
      liters: liters,
      pricePerLiter: price / liters,
      price: price,
      usedFuelAditives: _usedAditives,
      gasStation: _gasStationController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final currentCar = await carProvider.getCarById(widget.carId);
    if (currentCar != null && mileageValue > currentCar.mileage) {
      await carProvider.updateCarMileage(widget.carId, mileageValue);
      ref.invalidate(carDetailsProvider(widget.carId));
      ref.invalidate(carsProvider);
    }

    await ref.read(refuelServiceProvider)!.updateRefuel(
      carId: widget.carId,
      refuel: updated,
    );

    ref.invalidate(refuelByIdProvider((refuelId: widget.refuelId, carId: widget.carId)));
    ref.invalidate(refuelStatsProvider(widget.carId));
    ref.invalidate(refuelsPaginatorProvider(widget.carId));

    setState(() => _isSaving = false);

    if (mounted) {
      CustomSnackbar.show(
        context,
        type: AlertType.success,
        title: "Uspjeh",
        message: "Podaci o točenju uspješno ažurirani.",
      );
      GoRouter.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final refuelAsync = ref.watch(refuelByIdProvider((refuelId: widget.refuelId, carId: widget.carId)));

    return Scaffold(
      appBar: CustomAppBar(
        title: refuelAsync.when(
          data: (data) => data?.car?.brand ?? "Uredi zapis",
          loading: () => "Učitavanje...",
          error: (_, __) => "Greška",
        ),
        subtitle: refuelAsync.when(
          data: (data) => data?.car != null ? "${data!.car.year} ${data.car.model}" : "",
          loading: () => "Učitavanje...",
          error: (_, __) => "",
        ),
      ),

      body: refuelAsync.when(
        data: (data) {
          if (data == null) {
            return const Center(
              child: CustomAlert(
                type: AlertType.error,
                title: "Greška",
                message: "Podaci o točenju nisu pronađeni.",
              ),
            );
          }

          _populateFields(data.refuel);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildDatePicker(),

                  CustomTextField(
                    controller: _mileageController,
                    label: 'Kilometraža pri točenju',
                    icon: 'stash:data-numbers',
                    keyboardType: TextInputType.number,
                    suffixText: "KM",
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                    hint: "186 250 km",
                  ),
                  CustomTextField(
                    controller: _litersController,
                    label: 'Litara goriva',
                    icon: 'mdi:gas-pump',
                    keyboardType: TextInputType.number,
                    hint: "50.00 L",
                    suffixText: "L",
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                  ),
                  CustomTextField(
                    controller: _priceController,
                    label: 'Cijena',
                    icon: 'material-symbols:attach-money-rounded',
                    suffixText: "BAM",
                    hint: "105.5",
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Obavezno' : null,
                  ),

                  const SizedBox(height: 8),

                  CustomTextField(
                    controller: _gasStationController,
                    label: 'Benzinska',
                    icon: 'mdi:fuel',
                    hint: "INA, Petrol...",
                  ),

                  CustomTextField(
                    controller: _notesController,
                    label: 'Napomene',
                    icon: 'hugeicons:note',
                    hint: "Napravljeno dugo putovanje...",
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: _usedAditives,
                        onChanged: (v) => setState(() => _usedAditives = v ?? false),
                      ),
                      const Text("Korišten aditiv")
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          text: 'Odustani',
                          icon: 'eva:close-circle-outline',
                          outlined: true,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          onPressed: () => _save(data.refuel),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          text: 'Spremi',
                          icon: 'proicons:save',
                          isLoading: _isSaving,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Greška: $err")),
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
            children: const [
              IconifyIcon(icon: 'lets-icons:date-range-light', size: 20, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text("Datum točenja", style: TextStyle(fontWeight: FontWeight.w600)),
              Text(" *", style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDate == null
                    ? 'Odaberite datum'
                    : DateFormat('dd.MM.yyyy.').format(_selectedDate!),
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedDate == null ? Colors.grey : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
