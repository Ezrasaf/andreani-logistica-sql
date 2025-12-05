# 📦 Base de Datos Logística – Proyecto Andreani (SQL Server)

Este proyecto implementa una base de datos completa inspirada en procesos reales de logística farmacéutica:  
gestión de pedidos, control de lotes, consolidación en cajas, transporte, entregas e incidencias.

Incluye también KPIs, vistas analíticas, triggers de control y un DER profesional.

---

## 🧩 Modelo de Datos (DER)

El modelo está dividido en módulos para facilitar el entendimiento del negocio logístico:

- **Comercial:** clientes, pedidos y detalles.  
- **Almacén:** productos, lotes y consolidación de cajas.  
- **Distribución:** rutas, vehículos, operarios y entregas.  
- **Calidad:** trazabilidad e incidencias.

![DER Andreani](DER%20Completo.png)

---

## 🚀 Funcionalidades principales

### ✔ Modelo físico completo con todas las entidades del flujo logístico:
- EmpresaCliente  
- Producto  
- Lote  
- Pedido  
- DetallePedido  
- Caja / Caja_Producto  
- Vehiculo  
- Ruta  
- Operario  
- Entrega  
- Incidencia  

### ✔ Integridad y reglas de negocio
- Trigger que bloquea productos vencidos en pedidos  
- Validación de cantidades mayores a cero en cajas  
- Relaciones N:M (Caja–Lote) implementadas mediante tabla intermedia  

### ✔ KPIs implementados (vistas SQL)
- **Entregas conformes por zona**  
- **On Time Delivery Rate (OTD)**  
- **Índice de consolidación por caja**  
- **Trazabilidad completa por lote**  
- **Utilización promedio de flota**  
- **Incidencias por error de lote**  

---

## 📄 Archivo SQL principal

📌 `01_andreani_logistica.sql` contiene:

- Creación de la base de datos `AndreaniLogistica`  
- Creación de tablas y claves foráneas  
- Vistas para KPIs  
- Triggers de control  
- Procedimiento almacenado de trazabilidad por lote  
- Inserción de datos de prueba (mínimo 10 registros por tabla)

---

## 🧪 Cómo ejecutar el proyecto

1. Abrir **SQL Server Management Studio (SSMS)**  
2. Ejecutar el archivo completo `01_andreani_logistica.sql`  
3. Verificar tablas:  
   ```sql
   SELECT * FROM INFORMATION_SCHEMA.TABLES;
4. Verificar vistas:  
   ```sql
   SELECT * FROM INFORMATION_SCHEMA.VIEWS;
5. Probar KPIs principales:

SELECT * FROM vw_EntregasConformes;
SELECT * FROM KPI_OnTimeDeliveryRate;
SELECT * FROM KPI_TrazabilidadLote;
SELECT * FROM KPI_IndiceConsolidacion;
SELECT * FROM KPI_UtilizacionFlota;
SELECT * FROM KPI_IncidenciasErrorLote;

### 🎯 Conocimientos demostrados

Este proyecto demuestra habilidades clave de Ingeniería de Datos y Diseño de Bases de Datos:

Diseño de modelo de datos relacional

Normalización y relaciones 1:N y N:M

Integridad referencial mediante claves foráneas

Implementación de reglas de negocio con triggers

Automatización de análisis mediante vistas para KPIs

Procedimientos almacenados

Control de accesos y permisos (seguridad básica)

Simulación de un flujo logístico real (cadena de frío y trazabilidad)

📁 Estructura recomendada del repositorio
andreani-logistica-sql/
├─ 01_andreani_logistica.sql      # Script principal
├─ DER Completo.png               # Diagrama entidad-relación
└─ README.md                      # Documentación del proyecto


(Opcionalmente podés mover la imagen a una carpeta /docs para mayor prolijidad.)

### 👤 Autor

Ezrasaf
Estudiante de Ingeniería en Informática (UADE)
Interesado en SQL, Ingeniería de Datos, Backend y Automatización.

### ⭐ Valor para Portfolio

Este proyecto es ideal para demostrar:

Capacidad de modelar procesos de negocio complejos

Dominio de SQL Server y consultas avanzadas

Construcción de KPIs y analítica operativa

Aplicación de conceptos reales de logística y cadena de frío

Buenas prácticas en diseño y documentación técnica
