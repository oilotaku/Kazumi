import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/widget/state_presentation.dart';
import 'package:kazumi/bean/widget/tonal_card.dart';
import 'package:kazumi/pages/settings/sync/sync_settings_widgets.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/services/sync/webdav.dart';

class WebDavServerPage extends StatefulWidget {
  const WebDavServerPage({super.key});

  @override
  State<WebDavServerPage> createState() => _WebDavServerPageState();
}

class _WebDavServerPageState extends State<WebDavServerPage> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _passwordVisible = false;
  bool _busy = false;
  bool _failed = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _url.text = GStorage.getSetting(SettingsKeys.webDavURL);
    _username.text = GStorage.getSetting(SettingsKeys.webDavUsername);
    _password.text = GStorage.getSetting(SettingsKeys.webDavPassword);
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _failed = false;
      _message = '正在測試連線…';
    });
    try {
      await GStorage.putSetting(SettingsKeys.webDavURL, _url.text.trim());
      await GStorage.putSetting(
          SettingsKeys.webDavUsername, _username.text.trim());
      await GStorage.putSetting(SettingsKeys.webDavPassword, _password.text);
      await WebDav().init();
      _message = '連線成功，配置已儲存';
    } catch (e) {
      KazumiLogger().w('WebDAV configuration failed', error: e);
      await WebDav().setEnabled(false);
      _failed = true;
      _message = '連線失敗，同步已關閉。請檢查伺服器地址、帳號和密碼後重試。';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: SettingsDetailScaffold(
          title: const Text('同步伺服器'),
          body: SyncPageBody(
            maxWidth: 640,
            children: [
              const SyncPageIntro(
                icon: Icons.dns_rounded,
                title: '連線 WebDAV',
                description: '填寫雲盤或伺服器提供的連線資訊。',
              ),
              TonalCard(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  onChanged: () {
                    if (_message != null && !_busy) {
                      setState(() => _message = null);
                    }
                  },
                  child: Column(
                    spacing: 20,
                    children: [
                      TextFormField(
                        controller: _url,
                        enabled: !_busy,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: '伺服器地址',
                          hintText: 'https://example.com/dav/',
                          border: OutlineInputBorder(),
                          errorMaxLines: 3,
                        ),
                        validator: (value) {
                          final uri = Uri.tryParse(value?.trim() ?? '');
                          if (uri == null ||
                              !['http', 'https'].contains(uri.scheme) ||
                              uri.host.isEmpty) {
                            return '請輸入完整的 http:// 或 https:// 地址';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _username,
                        enabled: !_busy,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: '使用者名稱',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: !_passwordVisible,
                        autocorrect: false,
                        enableSuggestions: false,
                        onFieldSubmitted: (_) => _save(),
                        decoration: InputDecoration(
                          labelText: '密碼或應用授權碼',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _passwordVisible ? '隱藏密碼' : '顯示密碼',
                            onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                            icon: Icon(_passwordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StateActionButton(
                onPressed: _busy ? null : _save,
                text: _busy ? '正在測試連線…' : '儲存並測試',
                icon: Icons.cloud_done_rounded,
              ),
              if (_message != null)
                SyncFeedback(message: _message!, error: _failed, busy: _busy),
              if (_message != null && !_busy && !_failed)
                TextButton(
                  onPressed: () => context.maybePop(),
                  child: const Text('返回同步設定'),
                ),
            ],
          ),
        ),
      );
}
