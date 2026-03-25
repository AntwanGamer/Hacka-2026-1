import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
/*
class Manifiesto {
  final int oil;
  final int diesel;
  final int oilFilter;
  final int dieselFilter;
  final int airFilter;
  final int trash;
  final String? observations;

  Manifiesto({
    required this.oil,
    required this.diesel,
    required this.oilFilter,
    required this.dieselFilter,
    required this.airFilter,
    required this.trash,
    this.observations,
  });
}
*/
class PdfGenerator {
  /// Genera el PDF calcado al formato oficial de SEMARNAT.
  static Future<Uint8List> generarPdfBytes({
    required dynamic m, // Tu objeto Manifiestos.current
    required String nombreBarco,
    required String nombreMaquinista,
    required String nombreCocinero,
    required String? svgEscudoString,
    DateTime? fechaDocumento,
  }) async {
    final pdf = pw.Document();

    // --- DATOS Y FECHAS ---
    final fechaFinal = fechaDocumento ?? DateTime.now();

    final meses = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];

    // Puedes usar la fecha de registro del manifiesto o la actual
    final dia = fechaFinal.day.toString();
    final mes = meses[fechaFinal.month - 1];
    final anio = fechaFinal.year.toString();

    // --- FUENTES Y ESTILOS ---
    // Usamos Helvetica porque es idéntica a la Arial/Sans del formato oficial
    /*final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();*/
    // TEST
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final styleLabel = pw.TextStyle(font: fontBold, fontSize: 9);
    final styleValue = pw.TextStyle(font: fontRegular, fontSize: 10);
    final styleHeaderGrey = pw.TextStyle(
      font: fontBold,
      fontSize: 16,
      color: PdfColors.grey700,
    );
    final styleHeaderSmallGrey = pw.TextStyle(
      font: fontRegular,
      fontSize: 6,
      color: PdfColors.grey700,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              children: [
                // ===================================================
                // 1. ENCABEZADO (Caja Redondeada)
                // ===================================================
                pw.Container(
                  height: 90,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2.5, color: PdfColors.black),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(14),
                    ),
                  ),
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5, color: PdfColors.black),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(10),
                      ),
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 130,
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text("SEMARNAT", style: styleHeaderGrey),
                              pw.SizedBox(height: 2),
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Container(
                                      height: 2,
                                      color: PdfColors.green900,
                                    ),
                                  ), // Verde más oscuro
                                  pw.SizedBox(width: 2),
                                  pw.Expanded(
                                    child: pw.Container(
                                      height: 2,
                                      color: PdfColors.red900,
                                    ),
                                  ), // Rojo más oscuro
                                ],
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                "SECRETARÍA DE\nMEDIO AMBIENTE\nY RECURSOS NATURALES",
                                textAlign: pw.TextAlign.center,
                                style: styleHeaderSmallGrey,
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(width: 8),
                        pw.Container(
                          width: 1,
                          height: 50,
                          color: PdfColors.grey400,
                        ),

                        pw.Spacer(),

                        // CENTRO: Escudo
                        pw.Container(
                          width: 65,
                          height: 65,

                          child: pw.Opacity(
                              opacity: 0.45,
                              child: svgEscudoString != null
                                  ? pw.SvgImage(svg: svgEscudoString)
                                  : pw.Container(),
                            ),
                        ),

                        pw.SizedBox(width: 32),

                        // DER: Datos
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              "SEMARNAT",
                              style: pw.TextStyle(font: fontBold, fontSize: 13),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Text(
                              "CENTRO DE ACOPIO 2024 AL 2034",
                              style: pw.TextStyle(fontSize: 10),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              "Número de Registro Ambiental BOO2604804813",
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              "Autorización 26-30-PS-11-10-13",
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              "Puerto Peñasco, Sonora C.P 83500",
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Puerto Peñasco, Sonora a ",
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                      _campoFechaCorto(dia, 25),
                      pw.Text(
                        " de ",
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                      _campoFechaCorto(mes, 70),
                      pw.Text(
                        " de ",
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                      _campoFechaCorto(anio, 35),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // ===================================================
                // 2. CUERPO DEL REPORTE (Caja Grande con Borde Grueso)
                // ===================================================
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(2.5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 2.5),
                    ),

                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1.5),
                      ),
                      child: pw.Stack(
                        children: [
                          // A. MARCA DE AGUA
                          pw.Positioned.fill(
                            child: pw.Center(
                                child: pw.Opacity(
                                opacity: 0.15,
                                child: svgEscudoString != null
                                    ? pw.SvgImage(
                                        svg: svgEscudoString,
                                        width: 350,
                                      )
                                    : pw.Container(),
                              ),
                            ),
                          ),
                          pw.Spacer(),
                          // B. CONTENIDO
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,

                            children: [
                              // --- SECCIÓN SUPERIOR: DATOS ---
                              pw.Padding(
                                padding: const pw.EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  10,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,

                                  children: [
                                    // FECHA
                                    pw.Align(
                                      alignment: pw.Alignment.centerRight,
                                      child: pw.Row(
                                        mainAxisSize: pw.MainAxisSize.min,
                                        children: [
                                          pw.Text("FECHA: ", style: styleLabel),
                                          pw.Container(
                                            width: 150,
                                            decoration: const pw.BoxDecoration(
                                              border: pw.Border(
                                                bottom: pw.BorderSide(width: 1),
                                              ),
                                            ),
                                            child: pw.Text(
                                              "$dia/$mes/$anio",
                                              textAlign: pw.TextAlign.center,
                                              style: styleValue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    pw.SizedBox(height: 25),

                                    // CAMPOS DE DATOS
                                    _renglonDato(
                                      "NOMBRE DEL BARCO:",
                                      nombreBarco,
                                      fontBold,
                                      fontRegular,
                                    ),
                                    pw.SizedBox(height: 16),
                                    _renglonDato(
                                      "ACEITE USADO:",
                                      "${m.aceite} Litros",
                                      fontBold,
                                      fontRegular,
                                    ),
                                    pw.SizedBox(height: 16),
                                    _renglonDato(
                                      "BASURA:",
                                      "${m.basura} Kg",
                                      fontBold,
                                      fontRegular,
                                    ),
                                    /*pw.SizedBox(height: 16),
                                    _renglonDato(
                                      "DIESEL:",
                                      "${m.diesel} Litros",
                                      fontBold,
                                      fontRegular,
                                    ), // Agregado
                                    */
                                    pw.SizedBox(height: 16),
                                    _renglonDato(
                                      "FILTROS DE ACEITE:",
                                      "${m.filtro_aceite} Unidades",
                                      fontBold,
                                      fontRegular,
                                    ),
                                    pw.SizedBox(height: 16),
                                    _renglonDato(
                                      "FILTROS DE DIESEL:",
                                      "${m.filtro_diesel} Unidades",
                                      fontBold,
                                      fontRegular,
                                    ),
                                    pw.SizedBox(height: 16),
                                    _renglonDato(
                                      "FILTROS DE AIRE:",
                                      "${m.filtro_aire} Unidades",
                                      fontBold,
                                      fontRegular,
                                    ),
                                    /*pw.SizedBox(height: 16),
                                    _renglonDato(
                                      "BASURA:",
                                      "${m.basura} Kg",
                                      fontBold,
                                      fontRegular,
                                    ),*/ // Reordenado

                                    pw.SizedBox(height: 18),

                                    // OBSERVACIONES EN EL ESPACIO BLANCO
                                    pw.Container(
                                      width: double.infinity,
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text(
                                            "OBSERVACIONES:",
                                            style: styleLabel,
                                          ),
                                          pw.SizedBox(height: 6),
                                          pw.Text(
                                            m.observations?.isNotEmpty == true
                                                ? m.observations!
                                                : "Sin observaciones.",
                                            style: styleValue,
                                            textAlign: pw.TextAlign.justify,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              pw.Spacer(),
                              pw.Padding(
                                padding: const pw.EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  10,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,

                                  children: [
                                    pw.SizedBox(
                                      height: 30,
                                    ), // Espacio para firmar
                                    pw.Container(
                                      width: 250, // Ancho de la línea de firma
                                      decoration: const pw.BoxDecoration(
                                        border: pw.Border(
                                          bottom: pw.BorderSide(width: 1.5),
                                        ),
                                      ),
                                    ),
                                    pw.SizedBox(height: 3),
                                    pw.Text(
                                      "RECIBE: Oficial Comisionado para\nrecolección de Basura y Residuos Aceitosos\n(MARPOL ANEXO V)",
                                      style: pw.TextStyle(
                                        font: fontRegular,
                                        fontSize: 8,
                                      ), // Fuente pequeña como en la imagen
                                    ),
                                  ],
                                ),
                              ),
                              pw.Spacer(),

                              // --- SECCIÓN INFERIOR: FIRMAS (Separada por línea) ---
                              pw.Container(
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    top: pw.BorderSide(
                                      width: 2,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ),
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      "RECIBE: Comisionado para recolección de...",
                                      style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 9,
                                      ),
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Text(
                                      "Basura y Residuos Aceitosos (MARPOL - ANEXO)",
                                      style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 9,
                                      ),
                                    ),

                                    pw.SizedBox(
                                      height: 50,
                                    ), // Espacio para firmas

                                    pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.end,
                                      children: [
                                        _bloqueFirma(
                                          "RESPONSABLE DE ENTREGA DE\nLIQUIDOS\n(ACEITE USADO)",
                                          "",
                                          140,
                                          fontBold,
                                          fontRegular,
                                        ),
                                        _bloqueFirma(
                                          "MOTORISTA:",
                                          nombreMaquinista,
                                          120,
                                          fontBold,
                                          fontRegular,
                                        ),
                                        _bloqueFirma(
                                          "COCINERO:",
                                          nombreCocinero,
                                          120,
                                          fontBold,
                                          fontRegular,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 5),

                // PIE DE PÁGINA
                pw.Text(
                  "Av. La Dársena entre 7 y 8 recinto portuario tel.: 638 105 6030. Comisionado de líquidos y sólidos 1er.\noficial líquidos y sólidos. Francisco Javier Bojórquez Ochoa.",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: fontBold, fontSize: 6),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // WIDGETS AUXILIARES
  // ---------------------------------------------------------------------------

  // Genera: __________ (Para la fecha arriba)
  static pw.Widget _campoFechaCorto(String texto, double ancho) {
    return pw.Container(
      width: ancho,
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      child: pw.Text(
        texto,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // Genera: LABEL: ___________________VALOR___________________
  static pw.Widget _renglonDato(
    String label,
    String valor,
    pw.Font fontLabel,
    pw.Font fontValue,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fontLabel,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                valor,
                style: pw.TextStyle(font: fontValue, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Bloque de firma
  static pw.Widget _bloqueFirma(
    String cargo,
    String nombre,
    double width,
    pw.Font fontBold,
    pw.Font fontReg,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(height: 2),
        // LA LÍNEA
        pw.Container(width: width, height: 1, color: PdfColors.black),

        pw.SizedBox(height: 3),
        pw.Container(
          height: 30,
          alignment: pw.Alignment.topCenter,
          child: pw.Column(
            children: [
              pw.Text(
                cargo,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (nombre.isNotEmpty)
                pw.Text(
                  nombre,
                  style: pw.TextStyle(font: fontReg, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
