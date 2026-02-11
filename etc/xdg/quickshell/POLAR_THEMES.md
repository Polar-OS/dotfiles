# Polar Color Schemes

Temas personalizados para el sistema Quickshell con integración completa mediante tinty.

## Descripción

**Polar** es un esquema de colores diseñado para ser **refrescante y acogedor** a la vez:

### Polar Dark 
- **Concepto**: Noche polar bajo hielo glaciar
- **Paleta**: Azules oceánicos profundos (#0d1520) con acentos de hielo fresco (#7de4f0)
- **Sensación**: Fresco como agua helada, pero suave y no hiriente a la vista
- **Colores principales**:
  - Background: Azul océano profundo (#0d1520)
  - Accent: Agua helada cyan (#7de4f0) - color característico
  - Foreground: Blanco hielo suave (#d4e4f0)
  - Verdes: Menta fresca (#a8dfb8)
  - Rosas: Coral suave (#ff9eb5)

### Polar Light
- **Concepto**: Aurora boreal sobre hielo blanco
- **Paleta**: Blanco hielo puro (#f0f8ff) con acentos vibrantes pero no hirientes
- **Sensación**: Luminoso y refrescante como una brisa marina
- **Colores principales**:
  - Background: Blanco hielo puro (#f0f8ff)
  - Accent: Ocean teal (#0891b2) - color característico
  - Foreground: Océano profundo (#1a3d5c)
  - Verdes: Bosque fresco (#0d9e6e)
  - Naranjas: Tangerina brillante (#ff8533)

## Instalación

Los temas ya están instalados en:
```
~/.local/share/tinted-theming/tinty/repos/schemes/base16/polar-dark.yaml
~/.local/share/tinted-theming/tinty/repos/schemes/base16/polar-light.yaml
```

## Uso

### Cambio rápido con script helper:
```bash
polar-theme dark   # Activa Polar Dark
polar-theme light  # Activa Polar Light
polar-theme d      # Shortcut para dark
polar-theme l      # Shortcut para light
```

### Cambio con tinty directo:
```bash
tinty apply base16-polar-dark
tinty apply base16-polar-light
```

### Cambio desde Quickshell UI:
Los temas están disponibles en el selector de temas del panel como:
- "Polar Dark"
- "Polar Light"
- "base16-polar-dark"
- "base16-polar-light"

## Integración

Tinty aplica automáticamente los temas a:
- ✅ **Quickshell** (este shell)
- ✅ **Niri** (compositor Wayland)
- ✅ **Ghostty** (terminal)
- ✅ **tmux** (multiplexor)
- ✅ **Neovim** (editor)
- ✅ **GTK** (aplicaciones GTK)
- ✅ **OpenCode** (editor de código)

Todos cambian automáticamente al ejecutar `tinty apply`.

## Filosofía de diseño

Los colores Polar están diseñados para:
1. **Refrescar** - Colores que recuerdan agua fresca, hielo, menta
2. **Acoger** - Tonos suaves que no cansan la vista
3. **Contraste saludable** - Legibilidad sin dureza
4. **Coherencia** - Misma filosofía en dark y light

**Evitamos**:
- ❌ Colores saturados que hieran la vista
- ❌ Contrastes extremos que cansen
- ❌ Tonos apagados sin vida

**Favorecemos**:
- ✅ Azules y cyans refrescantes como color característico
- ✅ Verdes menta y bosque para indicar "bien"
- ✅ Rosas/corales suaves en vez de rojos duros
- ✅ Cremas y dorados en vez de amarillos chillones

## Mantenimiento

### Editar esquemas:
```bash
nano ~/.local/share/tinted-theming/tinty/repos/schemes/base16/polar-dark.yaml
nano ~/.local/share/tinted-theming/tinty/repos/schemes/base16/polar-light.yaml
```

### Regenerar templates después de editar:
```bash
cd ~/.local/share/tinted-theming/tinty/repos/schemes
git add base16/polar-*.yaml
git commit -m "Update Polar themes"

# Regenerar todos los templates
for repo in niri tmux ghostty opencode quickshell vim gtk; do
    tinty build ~/.local/share/tinted-theming/tinty/repos/$repo
done

# Aplicar cambios
tinty apply base16-polar-dark
```

## Integración con Matugen

Tienes dos sistemas de temas:

### Tinty (estático) - Polar themes
- Colores predefinidos y consistentes
- Cambio manual con `tinty apply` o `polar-theme`
- Esquemas: `base16-polar-dark`, `base16-polar-light`
- **Uso**: Cuando quieres colores específicos y consistentes

### Matugen (dinámico) - Wallpaper-based
- Colores generados desde tu wallpaper
- Genera automáticamente al cambiar wallpaper
- Temas: `dynamic`, `dynamic-inverted` en Quickshell
- **Uso**: Cuando quieres que el sistema combine con tu wallpaper

### Cambiar entre sistemas:

```bash
# Usar Polar (estático)
polar-theme dark
polar-theme light

# Usar dinámico desde wallpaper (si ya configuraste matugen)
matugen image ~/Pictures/Wallpapers/tu-wallpaper.png

# Ver el tema actual en Quickshell
jq '.current.name' ~/.config/quickshell/static-colors.json
```

**Nota**: Ambos sistemas pueden coexistir. Tinty actualiza `static-colors.json` con el tema "current", mientras que matugen actualiza `dynamic-colors.json` con temas "dynamic" y "dynamic-inverted". Quickshell puede usar cualquiera de los dos seleccionando el tema apropiado en la UI.

## Archivos del sistema

### Quickshell (temas estáticos):
- `~/.config/quickshell/themes.json` - Define "polar-dark" y "polar-light"
- `~/.config/quickshell/static-colors.json` - Generado por tinty hook
- `~/.config/quickshell/dynamic-colors.json` - Generado por matugen (dinámico)

### Tinty (esquemas base16):
- `~/.local/share/tinted-theming/tinty/repos/schemes/base16/polar-*.yaml`

### Matugen (dinámico desde wallpaper):
- `~/.config/matugen/config.toml` - Configuración
- `~/.config/matugen/templates/quickshell-dynamic.json` - Template para Quickshell

### Helper scripts:
- `~/.local/bin/polar-theme` - Script para cambio rápido
- `~/.local/bin/polar-palette` - Muestra la paleta de colores
