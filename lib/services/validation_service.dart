import 'dart:math';

class ValidationService {

  static final Map<String, Map<String, List<String>>> _messages = {

    "ansiedad": {

      "alto": [
        "Parece que la ansiedad está bastante fuerte ahora. Probemos algo breve para bajar un poco la intensidad.",
        "Suena como si la ansiedad estuviera muy presente en este momento. Intentemos algo corto para ayudar a calmar el cuerpo.",
        "Gracias por decírmelo. Cuando la ansiedad sube mucho, empezar por algo simple puede ayudar.",
        "Entiendo. Si la ansiedad está así de intensa, bajar el ritmo un momento suele ayudar bastante.",
      ],

      "medio": [
        "Parece que hay algo de ansiedad ahora. Podemos intentar algo breve para bajar un poco la tensión.",
        "Entiendo. Cuando la ansiedad aparece así, una pausa corta puede ayudar a recuperar equilibrio.",
        "Gracias por decirlo. Probemos algo rápido para ayudarte a sentirte un poco más tranquilo.",
      ],

      "bajo": [
        "Parece que hay un poco de ansiedad ahora. ¿Quieres contarme qué está pasando?",
        "Entiendo. A veces hablar un momento ayuda a ordenar lo que está pasando.",
        "Si quieres, puedes contarme un poco más.",
      ],
    },

    "bloqueado": {

      "alto": [
        "Suena como si te sintieras bastante bloqueado ahora.",
        "Cuando todo se siente bloqueado, empezar con algo simple puede ayudar.",
        "A veces el bloqueo se afloja empezando con un paso pequeño.",
      ],

      "medio": [
        "Parece que estás algo bloqueado.",
        "Cuando la mente se queda atrapada, una acción corta puede ayudar.",
        "Probemos algo pequeño para ayudarte a retomar ritmo.",
      ],

      "bajo": [
        "Parece un pequeño bloqueo.",
        "A veces hablar un poco ayuda a ordenar las ideas.",
        "Si quieres podemos mirar juntos qué está pasando.",
      ],
    },

    "molesto": {

      "alto": [
        "Suena como si el enojo estuviera bastante fuerte ahora.",
        "Cuando el enojo sube mucho, una pausa puede ayudar a recuperar claridad.",
        "Parece que la molestia está muy presente ahora.",
      ],

      "medio": [
        "Parece que hay algo de molestia ahora.",
        "A veces una pequeña pausa ayuda a mirar las cosas con más calma.",
        "Suena como si algo te estuviera incomodando bastante.",
      ],

      "bajo": [
        "Parece que algo te molestó un poco.",
        "A veces hablarlo ayuda a bajar la tensión.",
        "Podemos mirar juntos lo que ocurrió.",
      ],
    },

    "triste": {

      "alto": [
        "Lamento que te estés sintiendo así.",
        "Suena como un momento difícil.",
        "Cuando la tristeza es fuerte, no tienes que pasar por esto solo.",
      ],

      "medio": [
        "Parece que hay algo de tristeza ahora.",
        "A veces hablar sobre lo que sentimos ayuda.",
        "Podemos tomarnos un momento para mirarlo juntos.",
      ],

      "bajo": [
        "Parece un momento un poco triste.",
        "A veces poner en palabras lo que sentimos ayuda.",
        "Si quieres, podemos hablarlo.",
      ],
    },

    "sobrepasado": {

      "alto": [
        "Parece que hay demasiadas cosas al mismo tiempo ahora.",
        "Suena como si todo estuviera siendo demasiado ahora.",
        "Cuando todo se acumula así, empezar por algo pequeño puede ayudar.",
      ],

      "medio": [
        "Parece que hay bastante en tu mente ahora.",
        "Cuando hay muchas cosas al mismo tiempo, una pequeña pausa puede ayudar.",
        "Probemos algo corto para recuperar un poco de espacio mental.",
      ],

      "bajo": [
        "Parece que hay varias cosas dando vueltas en tu mente.",
        "A veces hablarlo ayuda a ordenar lo que está pasando.",
        "Podemos mirar juntos lo que te está preocupando.",
      ],
    },

  };

  static String getMessage(String emotion, String intensity) {

    final messages = _messages[emotion.toLowerCase()]?[intensity.toLowerCase()];

    if (messages == null || messages.isEmpty) {
      return "Estoy aquí contigo.";
    }

    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

}