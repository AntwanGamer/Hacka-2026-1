class ReciboBasuronModelo {
  final int id;
  final String tipoDesecho;
  final String fechaRecibo;
  final int cantidadKg;
  final String idUsuario;
  final String recibo; // URL o nombre del archivo

  ReciboBasuronModelo({
    required this.id,
    required this.tipoDesecho,
    required this.fechaRecibo,
    required this.cantidadKg,
    required this.idUsuario,
    required this.recibo,
  });

  factory ReciboBasuronModelo.fromJson(Map<String, dynamic> json) {
    return ReciboBasuronModelo(
      id: json['id'] ?? 0,
      tipoDesecho: json['tipo_desecho'] ?? '',
      fechaRecibo: json['fecha_recibo'] ?? '',
      cantidadKg: json['cantidad_kg'] ?? 0,
      idUsuario: json['id_usuario'] ?? '',
      recibo: json['recibo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo_desecho': tipoDesecho,
      'fecha_recibo': fechaRecibo,
      'cantidad_kg': cantidadKg,
      'id_usuario': idUsuario,
      'recibo': recibo,
    };
  }
}
