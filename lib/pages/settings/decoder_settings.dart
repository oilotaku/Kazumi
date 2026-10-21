import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/bean/settings/settings_list.dart';

class DecoderSettings extends StatefulWidget {
  const DecoderSettings({super.key});

  @override
  State<DecoderSettings> createState() => _DecoderSettingsState();
}

class _DecoderSettingsState extends State<DecoderSettings> {
  late String _decoder = GStorage.getSetting(SettingsKeys.hardwareDecoder);

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: const Text('硬體解碼器'),
      body: SettingsList(
        sections: [
          SettingsRadioSection<String>(
            title: Text('選擇不受支援的解碼器將回退到軟體解碼'),
            groupValue: _decoder,
            onChanged: (String? value) {
              if (value != null) {
                GStorage.putSetting<String>(
                    SettingsKeys.hardwareDecoder, value);
                setState(() {
                  _decoder = value;
                });
              }
            },
            tiles: hardwareDecodersList.entries
                .map((e) => SettingsTile<String>.radioTile(
                      title: Text(e.key),
                      description: Text(e.value),
                      radioValue: e.key,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
