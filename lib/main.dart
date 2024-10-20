import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:excelx/model.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool loading = false;
  String name = 'f';
  DateTime? start, end;
  List<List> links = [];
  List ready = [];
  File? file;

  Future<void> createAndSaveExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    for (var e in ready) {
      sheet.appendRow([
        TextCellValue(e['link']),
        TextCellValue(e['n1']),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(e['n2']),
        TextCellValue(e['status'])
      ]);
    }

    // // Get the directory to save the file
    Directory? directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/${name.replaceAll('.csv', '')}.xlsx';

    file = File(path);
    await file?.writeAsBytes(excel.save() ?? []);
    setState(() {
      loading = false;
      end = DateTime.now();
    });
    print('Excel file saved at: $path');
  }

  Future<void> importExcel() async {
    File? pickedFile;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        loading = true;
      });
      pickedFile = File(result.files.single.path.toString());

      final input = pickedFile.openRead();
      List<List<dynamic>>? csvData = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();
      setState(() {
        name = result.names.first ?? 'f';
        links = csvData;
        start = DateTime.now();
        ready.clear();
        end = null;
      });

      for (int i = 0; i < csvData.length; i++) {
        var link = csvData[i].join(', ').split(',')[1];
        try {
          var pK = link
              .replaceFirst('https://rakbank.simplify.com/invoicing/pay/#/', '')
              .split('/id/')
              .first
              .trim();
          var id = link
              .replaceFirst('https://rakbank.simplify.com/invoicing/pay/#/', '')
              .split('/id/')
              .last
              .trim();

          var headers = {
            'Accept': 'application/json, text/plain, */*',
          };
          var request = http.Request(
              'GET',
              Uri.parse(
                  'https://rakbank.simplify.com/commerce/invoice-details?publicKey=$pK&uuid=$id'));

          request.headers.addAll(headers);

          http.StreamedResponse response = await request.send();

          if (response.statusCode == 200) {
            var datar = InvoiceResponse.fromJson(
                jsonDecode(await response.stream.bytesToString()));

            setState(() {
              ready.add({
                'link': link,
                'n1': csvData[i].join(', ').split(',')[2].toString(),
                'n2': csvData[i].join(', ').split(',')[5].toString(),
                'status': datar.invoice.status
              });
            });
          }
        } catch (e) {
          print('$link :: $e');
        }
      }
    }

    createAndSaveExcel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loading
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        loading = false;
                      });
                    },
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : MaterialButton(
                    onPressed: () {
                      importExcel();
                    },
                    color: Colors.blue,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: const Text(
                      'Pick',
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(height: 20),
            if (file != null)
              MaterialButton(
                onPressed: () {
                  launchUrl(Uri.file(file!.path
                      .replaceAll('${name.replaceAll('.csv', '')}.xlsx', '')));
                },
                color: Colors.grey,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'File Name: $name',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Available links: ${links.length}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Done: ${ready.length}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (end != null)
                    Text(
                      'Time: ${end!.difference(start!).inSeconds} seconds',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            MaterialButton(
              onPressed: () {
                setState(() {
                  name = '';
                  file = null;
                  ready.clear();
                  links.clear();
                });
              },
              color: Colors.red,
              textColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
