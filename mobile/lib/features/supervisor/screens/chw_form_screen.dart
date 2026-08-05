import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/tr.dart';
import '../../profile/profile_repository.dart';
import '../supervisor_repository.dart';

class ChwFormScreen extends ConsumerStatefulWidget {
  const ChwFormScreen({super.key});

  @override
  ConsumerState<ChwFormScreen> createState() => _ChwFormScreenState();
}

class _ChwFormScreenState extends ConsumerState<ChwFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _facility = TextEditingController();
  final _district = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final profile = ref.read(profileProvider);
      profile.whenData((user) {
        if (user.district != null && user.district!.isNotEmpty) {
          _district.text = user.district!;
        }
      });
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _fullName.dispose();
    _facility.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(createChwProvider.notifier).create(
            _username.text.trim(),
            _password.text,
            _fullName.text.trim(),
            _facility.text.trim(),
            district: _district.text.trim().isNotEmpty ? _district.text.trim() : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'supervisor.createChwAccount'))),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'supervisor.createChwFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = ref.watch(createChwProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'supervisor.addChw'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _fullName,
                label: tr(ref, 'supervisor.fullName'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _username,
                label: tr(ref, 'supervisor.username'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _password,
                label: tr(ref, 'supervisor.temporaryPassword'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _facility,
                label: tr(ref, 'supervisor.facilityLabel'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _district,
                label: tr(ref, 'auth.district'),
                hint: tr(ref, 'auth.districtHint'),
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                creating ? tr(ref, 'common.creating') : tr(ref, 'supervisor.createChwAccount'),
                onPressed: creating ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
