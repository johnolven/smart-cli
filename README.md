# Smart CLI

Smart CLI es una herramienta de línea de comandos que permite interactuar con modelos de lenguaje como ChatGPT y Claude directamente desde tu terminal. Ofrece una interfaz sencilla para realizar consultas, mantener conversaciones interactivas y gestionar el historial de tus interacciones.

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