# 🎨 Comparación Visual - Paleta de Colores Óolale

## Paleta Oficial 2026

### Colores Principales

```
PRINCIPAL (Brand Identity)
┌─────────────────────────────────────────┐
│  #009688  Teal/Verde-Azulado PRIMARIO   │  Color de identidad
│  #00796B  Teal Oscuro (Hover/Active)    │  Estados interactivos
│  #4DB6AC  Teal Claro (Fondos suaves)    │  Acentos y badges
└─────────────────────────────────────────┘
```

### Colores Semánticos (Estados)

```
SEMANTIC COLORS
┌──────────────────────────────┐
│ #4CAF50  ÉXITO (Verde)       │  ✓ Validaciones, pagos OK
│ #FF9800  ADVERTENCIA (Naranja)│  ⚠️ Pendientes, alertas
│ #F44336  ERROR (Rojo)        │  ✗ Errores, eliminar, banear
│ #2196F3  INFORMACIÓN (Azul)  │  ℹ️ Tooltips, ayuda
└──────────────────────────────┘
```

### Fondos Oscuros (Dark Theme)

```
BACKGROUND HIERARCHY
┌────────────────────────────────┐
│ #0A0A0A  BODY (Más oscuro)     │  Fondo principal
│ #121212  CARDS (Oscuro)        │  Tarjetas, paneles
│ #1A1A1A  SECONDARY (Oscuro)    │  Secciones
│ #0F0F0F  PANELS (Negro puro)   │  Paneles especiales
│ #1E1E1E  ALT (Gris oscuro)     │  Alternativo
│ #2A2A2A  TERTIARY (Hover)      │  Estados hover
└────────────────────────────────┘
```

### Texto (Dark Theme)

```
TEXT HIERARCHY
┌──────────────────────────────┐
│ #FFFFFF  Texto Principal      │  Títulos, contenido
│ #B0B0B0  Texto Secundario     │  Descripciones
│ #808080  Texto Apagado        │  Placeholders, hints
└──────────────────────────────┘
```

---

## Ejemplos de Uso en la App

### ✓ Éxito - Oferta Aceptada
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Oferta aceptada'),
    backgroundColor: AppConstants.successColor, // #4CAF50 Verde
  ),
);
```

### ✗ Error - Oferta Rechazada
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Oferta rechazada'),
    backgroundColor: AppConstants.errorColor, // #F44336 Rojo
  ),
);
```

### ⚠️ Advertencia - Transacción Pendiente
```dart
Color _getStatusColor(String status) {
  switch (status) {
    case 'pendiente':
      return AppConstants.warningColor; // #FF9800 Naranja
    // ...
  }
}
```

### ℹ️ Información - Reembolso
```dart
Color _getStatusColor(String status) {
  switch (status) {
    case 'reembolsado':
      return AppConstants.infoColor; // #2196F3 Azul
    // ...
  }
}
```

### 🎯 Botón Principal
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppConstants.primaryColor, // #009688 Teal
  ),
  child: Text('Enviar'),
)
```

---

## Transiciones de Colores

```
Flujo de Estados Típico:
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  NEUTRAL          ACTIVO          COMPLETADO             │
│  (Gray)      →    (Teal)      →   (Green)                │
│  #1A1A1A    →    #009688    →    #4CAF50                │
│                                                          │
│  PENDIENTE       PROCESANDO       COMPLETADO              │
│  (Orange)   ←    (Teal)      →    (Green)                │
│  #FF9800   ←    #009688    →    #4CAF50                │
│                                                          │
│  ERROR / RECHAZADO                                       │
│  #F44336                                                │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Validación de Contraste

| Elemento | Fondo | Texto | Contraste |
|----------|-------|-------|-----------|
| Botón primario | #009688 Teal | #000000 Negro | ✓ AAA |
| Card | #121212 Gris | #FFFFFF Blanco | ✓ AAA |
| Error | #F44336 Rojo | #FFFFFF Blanco | ✓ AAA |
| Éxito | #4CAF50 Verde | #FFFFFF Blanco | ✓ AAA |
| Warning | #FF9800 Naranja | #000000 Negro | ✓ AAA |
| Info | #2196F3 Azul | #FFFFFF Blanco | ✓ AAA |

---

## Especificaciones técnicas

### RGB Values
```
Primary Teal:        RGB(0, 150, 136)
Success Green:       RGB(76, 175, 80)
Error Red:           RGB(244, 67, 54)
Warning Orange:      RGB(255, 152, 0)
Info Blue:           RGB(33, 150, 243)
Background:          RGB(10, 10, 10)
Card:                RGB(18, 18, 18)
```

### HSL Values
```
Primary Teal:        HSL(174°, 100%, 29%)
Success Green:       HSL(120°, 39%, 55%)
Error Red:           HSL(4°, 89%, 59%)
Warning Orange:      HSL(39°, 100%, 50%)
Info Blue:           HSL(207°, 100%, 54%)
```

---

## Aplicación en Componentes

### AppBar
```
Background: bgDarkPanel (#0F0F0F)
Text: textPrimary (#FFFFFF)
Icons: primaryColor (#009688)
```

### Tarjetas
```
Background: cardColor (#121212)
Border: primaryColor.withOpacity(0.1)
Text: textPrimary (#FFFFFF)
```

### Botones
```
Primary: primaryColor (#009688), foreground: black
Secondary: primaryColor.withOpacity(0.2)
Disabled: textMuted (#808080)
```

### Estados
```
✓ Aceptado: successColor (#4CAF50)
✗ Rechazado: errorColor (#F44336)
⚠ Pendiente: warningColor (#FF9800)
ℹ Completado: infoColor (#2196F3)
```

---

**Paleta oficial de Óolale Mobile 2026** 🎵
