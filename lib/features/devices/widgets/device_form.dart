import 'package:flutter/material.dart';

import '../../../models/device.dart';

class DeviceFormData {
  const DeviceFormData({
    required this.name,
    required this.category,
    required this.serialNumber,
    required this.location,
    required this.lastMaintenanceDate,
    required this.maintenanceIntervalMonths,
    required this.maintenanceCalculationMethod,
  });

  final String name;
  final String category;
  final String serialNumber;
  final String location;
  final DateTime lastMaintenanceDate;
  final int maintenanceIntervalMonths;
  final MaintenanceCalculationMethod maintenanceCalculationMethod;
}

class DeviceForm extends StatefulWidget {
  const DeviceForm({
    super.key,
    required this.submitLabel,
    required this.submitIcon,
    required this.onSubmit,
    this.initialDevice,
  });

  final String submitLabel;
  final IconData submitIcon;
  final Device? initialDevice;
  final Future<void> Function(DeviceFormData data) onSubmit;

  @override
  State<DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<DeviceForm> {
  static const List<int> _intervalOptions = [0, 1, 3, 6, 12, 18, 24, 36];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _serialController;
  late final TextEditingController _locationController;
  late DateTime _lastMaintenanceDate;
  late int _intervalMonths;
  late MaintenanceCalculationMethod _calculationMethod;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final device = widget.initialDevice;
    _nameController = TextEditingController(text: device?.name ?? '');
    _categoryController = TextEditingController(text: device?.category ?? '');
    _serialController = TextEditingController(text: device?.serialNumber ?? '');
    _locationController = TextEditingController(text: device?.location ?? '');
    _lastMaintenanceDate = device?.lastMaintenanceDate ?? DateTime.now();
    _intervalMonths = device?.maintenanceIntervalMonths ?? 6;
    _calculationMethod =
        device?.maintenanceCalculationMethod ??
        MaintenanceCalculationMethod.plannedDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime get _nextMaintenanceDate => Device.calculateNextMaintenanceDate(
    lastMaintenanceDate: _lastMaintenanceDate,
    maintenanceIntervalMonths: _intervalMonths,
  );

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunludur';
    }
    return null;
  }

  Future<void> _selectLastMaintenanceDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _lastMaintenanceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Son bakım tarihini seçin',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );

    if (pickedDate != null && mounted) {
      setState(() => _lastMaintenanceDate = pickedDate);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        DeviceFormData(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          serialNumber: _serialController.text.trim(),
          location: _locationController.text.trim(),
          lastMaintenanceDate: _lastMaintenanceDate,
          maintenanceIntervalMonths: _intervalMonths,
          maintenanceCalculationMethod: _calculationMethod,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormSection(
                    title: 'Cihaz bilgileri',
                    subtitle: 'Envanterde cihazı kolayca ayırt edecek bilgiler',
                    icon: Icons.precision_manufacturing_outlined,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          validator: _requiredValidator,
                          decoration: const InputDecoration(
                            labelText: 'Cihaz adı',
                            prefixIcon: Icon(Icons.devices_other_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _categoryController,
                          textInputAction: TextInputAction.next,
                          validator: _requiredValidator,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _serialController,
                          textInputAction: TextInputAction.next,
                          validator: _requiredValidator,
                          decoration: const InputDecoration(
                            labelText: 'Seri numarası',
                            prefixIcon: Icon(Icons.qr_code_2_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _locationController,
                          textInputAction: TextInputAction.done,
                          validator: _requiredValidator,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Konum',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: 'Bakım planı',
                    subtitle: 'Son bakım tarihi ve tekrar periyodu',
                    icon: Icons.event_repeat_outlined,
                    child: Column(
                      children: [
                        Material(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            onTap: _selectLastMaintenanceDate,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: const Icon(Icons.calendar_today_outlined),
                            title: const Text('Son bakım tarihi'),
                            subtitle: Text(
                              _formatDate(_lastMaintenanceDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: _intervalMonths,
                          decoration: const InputDecoration(
                            labelText: 'Bakım periyodu',
                            prefixIcon: Icon(Icons.update_rounded),
                            helperText:
                                '2 haftadan 36 aya kadar seçim yapabilirsiniz',
                          ),
                          items: _intervalOptions
                              .map(
                                (interval) => DropdownMenuItem<int>(
                                  value: interval,
                                  child: Text(Device.intervalLabel(interval)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _intervalMonths = value);
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.event_available_outlined,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sonraki bakım tarihi',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(_nextMaintenanceDate),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Device.intervalLabel(_intervalMonths),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: 'Bakım Ayarları',
                    subtitle:
                        'Sonraki bakım tarihinin nasıl hesaplanacağını seçin',
                    icon: Icons.tune_rounded,
                    child: Column(
                      children: [
                        _CalculationMethodOption(
                          selected:
                              _calculationMethod ==
                              MaintenanceCalculationMethod.plannedDate,
                          title: 'Planlanan tarihten itibaren',
                          badge: 'Recommended',
                          helperText:
                              'Bakım gecikse bile sonraki bakım planlanan tarihe göre hesaplanır.',
                          onTap: () => setState(
                            () => _calculationMethod =
                                MaintenanceCalculationMethod.plannedDate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CalculationMethodOption(
                          selected:
                              _calculationMethod ==
                              MaintenanceCalculationMethod.completionDate,
                          title: 'Tamamlanma tarihinden itibaren',
                          helperText:
                              'Sonraki bakım tarihi bakımın gerçekten tamamlandığı tarihten hesaplanır.',
                          onTap: () => setState(
                            () => _calculationMethod =
                                MaintenanceCalculationMethod.completionDate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(widget.submitIcon),
                      label: Text(
                        _isSubmitting ? 'Kaydediliyor...' : widget.submitLabel,
                      ),
                    ),
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

class _CalculationMethodOption extends StatelessWidget {
  const _CalculationMethodOption({
    required this.selected,
    required this.title,
    required this.helperText,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String title;
  final String helperText;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.55)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      helperText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
