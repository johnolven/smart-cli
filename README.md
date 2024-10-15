# Smart CLI

Smart CLI es una herramienta de línea de comandos que permite interactuar con modelos de lenguaje como ChatGPT y Claude directamente desde tu terminal. Ofrece una interfaz sencilla para realizar consultas, mantener conversaciones interactivas y gestionar el historial de tus interacciones.

## Importante: Tokens de API requeridos

Antes de comenzar, necesitarás obtener tokens de API tanto para ChatGPT (OpenAI) como para Claude (Anthropic). Estos tokens son esenciales para que Smart CLI pueda comunicarse con los modelos de lenguaje.

### Cómo obtener los tokens de API:

1. **Token de ChatGPT (OpenAI)**:
   - Ve a [https://platform.openai.com/](https://platform.openai.com/)
   - Inicia sesión o crea una cuenta si aún no tienes una
   - Ve a la sección "API Keys" en tu panel de control
   - Haz clic en "Create new secret key"
   - Copia y guarda el token generado en un lugar seguro

2. **Token de Claude (Anthropic)**:
   - Ve a [https://www.anthropic.com](https://www.anthropic.com)
   - Regístrate para obtener acceso a la API de Claude (puede requerir aprobación)
   - Una vez aprobado, accede a tu panel de control
   - Busca la sección de "API Keys" o similar
   - Genera un nuevo token y guárdalo de forma segura

**Nota**: Mantén tus tokens de API en secreto y no los compartas con nadie. Serás responsable de cualquier uso que se haga con ellos.

## Características

- Soporte para múltiples modelos de lenguaje (actualmente ChatGPT y Claude)
- Modo interactivo para conversaciones continuas
- Historial de conversaciones con capacidad de revisión y continuación
- Selección de modelos específicos para cada LLM
- Configuración personalizable y persistente

## Requisitos

- Bash 4.0 o superior
- jq
- curl
- Tokens de API para OpenAI (ChatGPT) y Anthropic (Claude)

## Instalación

1. Clona este repositorio:
   ```
   git clone https://github.com/johnolven/smart-cli.git
   cd smart-cli
   ```

2. Ejecuta el script de instalación:
   ```
   ./install.sh
   ```

3. Sigue las instrucciones en pantalla para configurar tus tokens de API y seleccionar tu LLM predeterminado.

## Uso

### Consulta rápida
```
sli "Tu pregunta aquí"
```

### Modo interactivo
```
sli -i
```

### Seleccionar modelo
```
sli -m
```

### Ver historial
```
sli -h
```

### Cambiar LLM predeterminado
```
sli -l
```

## Configuración

La configuración se almacena en `~/.config/smart-cli/config.json`. Incluye:

- Tokens de API
- LLM predeterminado
- Modelos seleccionados para cada LLM

## Historial

Las conversaciones se guardan en `~/.config/smart-cli/history/` con nombres de archivo que incluyen la fecha y hora de la conversación.

## Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue para discutir cambios mayores antes de enviar un pull request.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Descargo de responsabilidad

Este proyecto no está afiliado oficialmente con OpenAI o Anthropic. Asegúrate de cumplir con los términos de servicio de los proveedores de API al usar esta herramienta.