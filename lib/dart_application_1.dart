import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mysql_client/mysql_client.dart';

const apiKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

Future<void> main() async {
  final conn = await MySQLConnection.createConnection(
    host: 'localhost',
    port: 3306,
    userName: 'Aprendiz',
    password: '1234',
    databaseName: 'dbuser',
  );

  await conn.connect();

  final model1 = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: apiKey,
  );
  final definition1 = [
    "You are an AI that generates SQL queries. When I ask you for a person, I want you to only return an SQL query that looks for the first name of the person in the database. The table in which the names are stored is called 'users' and the column containing the name is called 'name', Please return only matches based on the first name. Example: What is the age of juan? Answer: SELECT * FROM users WHERE name LIKE 'John%'"
  ];
  String words = "A que se dedica michael mayers?";

  final prompt1 = "$definition1 $words";
  final content1 = [Content.text(prompt1)];
  final response1 = await model1.generateContent(content1);

  var sqlQuery = response1.text;

  String formattedString = sqlQuery!
      .replaceAll(RegExp(r'.*```sql\s*'), '')
      .replaceAll(RegExp(r'\s*```.?'), '');

  var res = await conn.execute(formattedString);

  final results = res.rows.map((row) {
    return {
      'name': row.colAt(0),
      'age': row.colAt(1),
      'occupation': row.colAt(2),
    };
  }).toList();

  await conn.close();

  final model2 = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: apiKey,
  );

  final users = results
      .map((p) => '${p['name']} tiene ${p['age']} años y es ${p['occupation']}')
      .join(',');

  final definition2 = [
    'Eres sam, tu tarea es proporcionar informacion acerca de los usuarios que recibas de la base de datos, esa y solo esa es tu tarea si recibes una solicitud diferente devuelve como respuesta que no estas diseñada para esta tarea'
  ];

  final prompt2 = "$definition2 $users $words";
  final content2 = [Content.text(prompt2)];
  final response2 = await model2.generateContent(content2);

  print(response2.text);
}
