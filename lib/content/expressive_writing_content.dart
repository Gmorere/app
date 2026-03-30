class ExpressiveWritingContent {
  final String intro;
  final String prompt;
  final String placeholder;
  final String note;
  final String closing;

  const ExpressiveWritingContent({
    required this.intro,
    required this.prompt,
    required this.placeholder,
    required this.note,
    required this.closing,
  });
}

class ExpressiveWritingContentLibrary {
  static ExpressiveWritingContent get({
    required String emotion,
    required String intensity,
  }) {
    final normalizedEmotion = emotion.toLowerCase().trim();
    final normalizedIntensity = intensity.toLowerCase().trim();

    switch (normalizedEmotion) {
      case 'triste':
      case 'pena':
      case 'tristeza':
        return _buildSadnessContent(normalizedIntensity);
      default:
        return _buildDefaultContent(normalizedIntensity);
    }
  }

  static ExpressiveWritingContent _buildSadnessContent(String intensity) {
    switch (intensity) {
      case 'alto':
        return const ExpressiveWritingContent(
          intro:
              "No tienes que ordenar esto perfecto. A veces ayuda poner una parte afuera antes de seguir sosteniendolo por dentro.",
          prompt:
              "Escribe lo que mas pesa ahora, aunque salga desordenado.",
          placeholder:
              "Puedes escribir lo que estas sintiendo, lo que te dolio o lo que te esta costando sostener ahora...",
          note:
              "No hace falta escribir mucho ni bonito. Despues veras una salida breve, no un analisis largo.",
          closing:
              "No necesitas explicarlo perfecto. Solo sacar un poco de peso ya puede ayudar.",
        );

      case 'medio':
        return const ExpressiveWritingContent(
          intro:
              "A veces no hace falta responder ni entender todo al tiro. Primero puede ayudar ponerlo en palabras.",
          prompt:
              "Escribe lo que mas te esta doliendo o removiendo ahora.",
          placeholder:
              "Empieza por una frase simple. Por ejemplo: 'Lo que mas me pesa ahora es...'",
          note:
              "No hace falta ordenarlo. Despues veras una salida breve para ayudarte a mirar esto con un poco mas de espacio.",
          closing:
              "No se trata de resolverlo aqui. Se trata de que no quede todo apretado adentro.",
        );

      case 'bajo':
      default:
        return const ExpressiveWritingContent(
          intro:
              "Vamos a usar unas lineas para sacar un poco de esto hacia afuera.",
          prompt:
              "Escribe lo que mas te pesa ahora, sin exigirte mucho.",
          placeholder:
              "Puedes escribir una idea, una frase o unas pocas lineas...",
          note:
              "No hace falta escribir mucho. Con eso bastara para darte una salida breve.",
          closing:
              "Ponerlo en palabras tambien es una forma de acompanarte.",
        );
    }
  }

  static ExpressiveWritingContent _buildDefaultContent(String intensity) {
    switch (intensity) {
      case 'alto':
        return const ExpressiveWritingContent(
          intro:
              "A veces ayuda sacar un poco de esto hacia afuera antes de seguir.",
          prompt:
              "Escribe lo que mas te esta pesando ahora.",
          placeholder:
              "No hace falta que este ordenado. Solo escribe lo que salga...",
          note:
              "No hace falta que quede ordenado. Despues veras una salida breve, no una correccion.",
          closing:
              "No necesitas resolver todo ahora. Solo aflojar un poco la carga.",
        );

      case 'medio':
      case 'bajo':
      default:
        return const ExpressiveWritingContent(
          intro:
              "Vamos a usar unas lineas para poner esto un poco mas afuera.",
          prompt:
              "Escribe lo que mas pesa ahora.",
          placeholder:
              "Puedes empezar con una frase simple...",
          note:
              "No hace falta escribir mucho ni ordenado. Despues veras una salida breve.",
          closing:
              "A veces escribir un poco ya abre mas espacio.",
        );
    }
  }
}
