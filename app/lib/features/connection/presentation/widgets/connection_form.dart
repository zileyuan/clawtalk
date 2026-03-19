import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/connection_config.dart';
import '../providers/connection_form_provider.dart';

/// Reusable form widget for adding/editing connections
class ConnectionForm extends ConsumerStatefulWidget {
  final ConnectionConfig? initialConnection;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;

  const ConnectionForm({
    super.key,
    this.initialConnection,
    this.onSubmit,
    this.onCancel,
  });

  @override
  ConsumerState<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends ConsumerState<ConnectionForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _tokenController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hostController = TextEditingController();
    _portController = TextEditingController(text: '18789');
    _tokenController = TextEditingController();
    _passwordController = TextEditingController();

    // Initialize with existing data if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialConnection != null) {
        ref
            .read(connectionFormProvider.notifier)
            .initializeWithConnection(widget.initialConnection!);
        _updateControllers(widget.initialConnection!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateControllers(ConnectionConfig config) {
    _nameController.text = config.name;
    _hostController.text = config.host;
    _portController.text = config.port.toString();
    _tokenController.text = config.token ?? '';
    _passwordController.text = config.password ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(connectionFormProvider);

    return CupertinoFormSection.insetGrouped(
      header: const Text('CONNECTION DETAILS'),
      children: [
        // Name field
        CupertinoFormRow(
          prefix: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(CupertinoIcons.tag, size: 22),
          ),
          child: CupertinoTextField(
            controller: _nameController,
            placeholder: 'Connection Name',
            placeholderStyle: AppTextStyles.body.copyWith(
              color: CupertinoColors.placeholderText,
            ),
            onChanged: (value) {
              ref.read(connectionFormProvider.notifier).setName(value);
            },
            decoration: const BoxDecoration(),
            style: AppTextStyles.body.copyWith(color: CupertinoColors.black),
          ),
        ),
        if (formState.hasFieldError('name'))
          _buildErrorText(formState.getFieldError('name')!),

        // Host field
        CupertinoFormRow(
          prefix: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(CupertinoIcons.globe, size: 22),
          ),
          child: CupertinoTextField(
            controller: _hostController,
            placeholder: 'Host (e.g., localhost or 192.168.1.1)',
            placeholderStyle: AppTextStyles.body.copyWith(
              color: CupertinoColors.placeholderText,
            ),
            onChanged: (value) {
              ref.read(connectionFormProvider.notifier).setHost(value);
            },
            decoration: const BoxDecoration(),
            style: AppTextStyles.body.copyWith(color: CupertinoColors.black),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
        ),
        if (formState.hasFieldError('host'))
          _buildErrorText(formState.getFieldError('host')!),

        // Port field
        CupertinoFormRow(
          prefix: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(CupertinoIcons.number, size: 22),
          ),
          child: CupertinoTextField(
            controller: _portController,
            placeholder: 'Port',
            placeholderStyle: AppTextStyles.body.copyWith(
              color: CupertinoColors.placeholderText,
            ),
            onChanged: (value) {
              ref.read(connectionFormProvider.notifier).setPort(value);
            },
            decoration: const BoxDecoration(),
            style: AppTextStyles.body.copyWith(color: CupertinoColors.black),
            keyboardType: TextInputType.number,
          ),
        ),
        if (formState.hasFieldError('port'))
          _buildErrorText(formState.getFieldError('port')!),

        // TLS Toggle
        CupertinoFormRow(
          prefix: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(CupertinoIcons.lock_shield, size: 22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Use TLS/SSL'),
              CupertinoSwitch(
                value: formState.useTLS,
                onChanged: (_) {
                  ref.read(connectionFormProvider.notifier).toggleTLS();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
      child: Text(
        error,
        style: AppTextStyles.caption.copyWith(color: CupertinoColors.systemRed),
      ),
    );
  }
}

/// Extended form with authentication fields
class ConnectionFormWithAuth extends ConsumerStatefulWidget {
  final ConnectionConfig? initialConnection;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const ConnectionFormWithAuth({
    super.key,
    this.initialConnection,
    this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  ConsumerState<ConnectionFormWithAuth> createState() =>
      _ConnectionFormWithAuthState();
}

class _ConnectionFormWithAuthState
    extends ConsumerState<ConnectionFormWithAuth> {
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _tokenController;
  late final TextEditingController _passwordController;
  bool _showAuthSection = false;
  bool _showToken = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hostController = TextEditingController();
    _portController = TextEditingController(text: '18789');
    _tokenController = TextEditingController();
    _passwordController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset form first to clear any previous state
      ref.read(connectionFormProvider.notifier).reset();

      if (widget.initialConnection != null) {
        debugPrint(
          '[EDIT_FORM] Initializing with connection: ${widget.initialConnection!.name}',
        );
        debugPrint('[EDIT_FORM] Token: ${widget.initialConnection!.token}');
        debugPrint(
          '[EDIT_FORM] Password: ${widget.initialConnection!.password}',
        );

        ref
            .read(connectionFormProvider.notifier)
            .initializeWithConnection(widget.initialConnection!);
        _updateControllers(widget.initialConnection!);

        // Check if we should show auth section (non-empty token or password)
        final hasToken = widget.initialConnection!.token?.isNotEmpty ?? false;
        final hasPassword =
            widget.initialConnection!.password?.isNotEmpty ?? false;
        debugPrint(
          '[EDIT_FORM] hasToken: $hasToken, hasPassword: $hasPassword',
        );

        if (hasToken || hasPassword) {
          setState(() {
            _showAuthSection = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateControllers(ConnectionConfig config) {
    _nameController.text = config.name;
    _hostController.text = config.host;
    _portController.text = config.port.toString();
    _tokenController.text = config.token ?? '';
    _passwordController.text = config.password ?? '';
    debugPrint(
      '[EDIT_FORM] Controllers updated - token: "${_tokenController.text}", password: "${_passwordController.text}"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(connectionFormProvider);

    return Column(
      children: [
        // Connection Details Section
        CupertinoFormSection.insetGrouped(
          header: const Text('CONNECTION DETAILS'),
          children: [
            _buildTextField(
              controller: _nameController,
              icon: CupertinoIcons.tag,
              placeholder: 'Connection Name',
              onChanged: (v) =>
                  ref.read(connectionFormProvider.notifier).setName(v),
            ),
            if (formState.hasFieldError('name'))
              _buildErrorText(formState.getFieldError('name')!),
            _buildTextField(
              controller: _hostController,
              icon: CupertinoIcons.globe,
              placeholder: 'Host (e.g., localhost)',
              onChanged: (v) =>
                  ref.read(connectionFormProvider.notifier).setHost(v),
              keyboardType: TextInputType.url,
            ),
            if (formState.hasFieldError('host'))
              _buildErrorText(formState.getFieldError('host')!),
            _buildTextField(
              controller: _portController,
              icon: CupertinoIcons.number,
              placeholder: 'Port',
              onChanged: (v) =>
                  ref.read(connectionFormProvider.notifier).setPort(v),
              keyboardType: TextInputType.number,
            ),
            if (formState.hasFieldError('port'))
              _buildErrorText(formState.getFieldError('port')!),
            _buildSwitchRow(
              icon: CupertinoIcons.lock_shield,
              label: 'Use TLS/SSL',
              value: formState.useTLS,
              onChanged: (_) =>
                  ref.read(connectionFormProvider.notifier).toggleTLS(),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Authentication Section
        CupertinoFormSection.insetGrouped(
          header: Row(
            children: [
              const Text('AUTHENTICATION'),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _showAuthSection = !_showAuthSection;
                  });
                },
                child: Icon(
                  _showAuthSection
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
          children: _showAuthSection
              ? [
                  _buildPasswordField(
                    controller: _tokenController,
                    icon: CupertinoIcons.lock,
                    placeholder: 'Access Token (optional)',
                    onChanged: (v) =>
                        ref.read(connectionFormProvider.notifier).setToken(v),
                    isVisible: _showToken,
                    onToggleVisibility: () =>
                        setState(() => _showToken = !_showToken),
                  ),
                  _buildPasswordField(
                    controller: _passwordController,
                    icon: CupertinoIcons.lock,
                    placeholder: 'Password (optional)',
                    onChanged: (v) => ref
                        .read(connectionFormProvider.notifier)
                        .setPassword(v),
                    isVisible: _showPassword,
                    onToggleVisibility: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ]
              : [
                  CupertinoFormRow(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => setState(() => _showAuthSection = true),
                      child: const Text(
                        'Add Authentication',
                        style: TextStyle(color: CupertinoColors.activeBlue),
                      ),
                    ),
                  ),
                ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(icon, size: 22),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: AppTextStyles.body.copyWith(
          color: CupertinoColors.placeholderText,
        ),
        onChanged: onChanged,
        decoration: const BoxDecoration(),
        style: AppTextStyles.body.copyWith(color: CupertinoColors.black),
        keyboardType: keyboardType,
        obscureText: obscureText,
        autocorrect: false,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    required ValueChanged<String> onChanged,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(icon, size: 22),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: AppTextStyles.body.copyWith(
                color: CupertinoColors.placeholderText,
              ),
              onChanged: onChanged,
              decoration: const BoxDecoration(),
              style: AppTextStyles.body.copyWith(color: CupertinoColors.black),
              obscureText: !isVisible,
              autocorrect: false,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 8),
            onPressed: onToggleVisibility,
            child: Icon(
              isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              size: 20,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(icon, size: 22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
      child: Text(
        error,
        style: AppTextStyles.caption.copyWith(color: CupertinoColors.systemRed),
      ),
    );
  }
}
