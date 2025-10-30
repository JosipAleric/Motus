import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:motus/widgets/customAppBar.dart';
import '../../models/refuel_model.dart';
import '../../providers/car_provider.dart';
import '../../providers/refuel_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/customTextField.dart';

class AddRefuelScreen extends ConsumerStatefulWidget {
  final String carId;
  const AddRefuelScreen({super.key, required this.carId});

  @override
  ConsumerState<AddRefuelScreen> createState() => _AddRefuelScreenState();
}

class _AddRefuelScreenState extends ConsumerState<AddRefuelScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _mileageAtRefuelController = TextEditingController();
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _gasStationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _usedFuelAditives = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _mileageAtRefuelController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    _gasStationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRefuel() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(authStateChangesProvider).asData?.value;
    if (authUser == null) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška",
        message: "Korisnik nije ulogiran",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final num mileageAtRefuel = int.tryParse(_mileageAtRefuelController.text) ?? 0;
      final double liters = double.tryParse(_litersController.text) ?? 0;
      final double price = double.tryParse(_priceController.text) ?? 0;

      if (liters <= 0 || price <= 0) {
        throw Exception("Neispravan unos za količinu ili cijenu goriva.");
      }

      final double pricePerLiter = price / liters;

      final newRefuel = RefuelModel(
        id: '',
        date: _selectedDate,
        mileageAtRefuel: mileageAtRefuel,
        liters: liters,
        pricePerLiter: pricePerLiter,
        price: price,
        usedFuelAditives: _usedFuelAditives,
        gasStation: _gasStationController.text.trim().isEmpty
            ? null
            : _gasStationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        carId: widget.carId,
      );

      // dodaj refuel zapis
      final refuelService = ref.read(refuelServiceProvider);
      await refuelService.addRefuel(authUser.uid, widget.carId, newRefuel);

      // osvježi statistiku refuela
      ref.invalidate(refuelStatsProvider(widget.carId));
      ref.invalidate(refuelsProvider(widget.carId));

      // dohvati trenutni auto
      final carService = ref.read(carServiceProvider);
      final currentCar = await carService.getCarById(authUser.uid, widget.carId);

      // ažuriraj kilometražu samo ako je nova veća
      if (currentCar != null && mileageAtRefuel > (currentCar.mileage ?? 0)) {
        await carService.updateCarMileage(authUser.uid, widget.carId, mileageAtRefuel.toInt());
        ref.invalidate(carDetailsProvider(widget.carId));
        ref.invalidate(carsProvider);
      }

      if (mounted) {
        CustomSnackbar.show(
          context,
          type: AlertType.success,
          title: "Uspješno",
          message: "Podaci o točenju goriva su uspješno dodani.",
        );
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          type: AlertType.error,
          title: "Greška",
          message: "Greška pri spremanju: $e",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconifyIcon(icon: 'solar:calendar-broken', size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Datum točenja',
                  style: TextStyle(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}.',
                    style: const TextStyle(color: Color(0xFF4E4E4E)),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dodaj točenje goriva',
        showAddCarButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateSelector(),

              CustomTextField(
                controller: _mileageAtRefuelController,
                label: 'Kilometraža pri točenju',
                icon: 'stash:data-numbers',
                hint: '182440',
                suffixText: "KM",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),

              CustomTextField(
                controller: _litersController,
                label: 'Količina goriva (L)',
                icon: 'hugeicons:gas-station',
                hint: '45.50',
                suffixText: "L",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),

              CustomTextField(
                controller: _priceController,
                label: 'Ukupna cijena',
                icon: 'ri:money-euro-box-line',
                hint: '105.55',
                suffixText: "KM",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obavezno' : null,
              ),

              CustomTextField(
                controller: _gasStationController,
                label: 'Benzinska postaja (opcionalno)',
                icon: 'hugeicons:fuel-station',
                hint: 'INA, Petrol...',
              ),

              CustomTextField(
                controller: _notesController,
                label: 'Napomene (opcionalno)',
                icon: 'ion:ios-document-text-outline',
                hint: 'Put u Njemačku',
              ),

              const SizedBox(height: 15),

              // Checkbox za aditive
              Row(
                children: [
                  Checkbox(
                    value: _usedFuelAditives,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _usedFuelAditives = newValue ?? false;
                      });
                    },
                  ),
                  const Text('Korišteni aditivi za gorivo'),
                ],
              ),

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
                      onPressed: _saveRefuel,
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
}