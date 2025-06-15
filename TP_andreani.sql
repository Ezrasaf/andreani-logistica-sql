CREATE DATABASE AndreaniLogistica;
GO
USE AndreaniLogistica;
GO

CREATE TABLE EmpresaCliente (
    ID_Empresa INT PRIMARY KEY,
    Nombre NVARCHAR(100),
    CUIT CHAR(11)
);

CREATE TABLE Producto (
    ID_Producto INT PRIMARY KEY,
    NombreComercial NVARCHAR(100),
    CondicionConservacion NVARCHAR(50)
);

CREATE TABLE Lote (
    ID_Lote INT PRIMARY KEY,
    ID_Producto INT FOREIGN KEY REFERENCES Producto(ID_Producto),
    FechaVencimiento DATE,
    TemperaturaMin DECIMAL(4,2),
    TemperaturaMax DECIMAL(4,2)
);
CREATE TABLE Pedido (
    ID_Pedido INT PRIMARY KEY,
    ID_Empresa INT,
    FechaPedido DATE,
    Estado NVARCHAR(50),
    FOREIGN KEY (ID_Empresa) REFERENCES EmpresaCliente(ID_Empresa)
);

CREATE TABLE DetallePedido (
    ID_Detalle INT PRIMARY KEY,
    ID_Pedido INT,
    ID_Lote INT,
    Cantidad INT,
    FOREIGN KEY (ID_Pedido) REFERENCES Pedido(ID_Pedido),
    FOREIGN KEY (ID_Lote) REFERENCES Lote(ID_Lote)
);

CREATE TABLE Caja (
    ID_Caja INT PRIMARY KEY,
    CodigoBarras NVARCHAR(50),
    Peso DECIMAL(6,2)
);

CREATE TABLE Caja_Producto (
    ID_Caja INT,
    ID_Lote INT,
    Cantidad INT,
    PRIMARY KEY (ID_Caja, ID_Lote),
    FOREIGN KEY (ID_Caja) REFERENCES Caja(ID_Caja),
    FOREIGN KEY (ID_Lote) REFERENCES Lote(ID_Lote)
);

CREATE TABLE Vehiculo (
    ID_Vehiculo INT PRIMARY KEY,
    Patente NVARCHAR(10),
    Tipo NVARCHAR(50),
    CapacidadKg INT
);

CREATE TABLE Ruta (
    ID_Ruta INT PRIMARY KEY,
    Origen NVARCHAR(100),
    Destino NVARCHAR(100),
    TiempoEstimado INT
);

CREATE TABLE Operario (
    ID_Operario INT PRIMARY KEY,
    Nombre NVARCHAR(100),
    Cargo NVARCHAR(50)
);

CREATE TABLE Entrega (
    ID_Entrega INT PRIMARY KEY,
    ID_Caja INT,
    ID_Ruta INT,
    ID_Vehiculo INT,
    ID_Operario INT,
    FechaEntrega DATE,
    RecibidoConforme NVARCHAR(2),
    Zona NVARCHAR(50),
    FOREIGN KEY (ID_Caja) REFERENCES Caja(ID_Caja),
    FOREIGN KEY (ID_Ruta) REFERENCES Ruta(ID_Ruta),
    FOREIGN KEY (ID_Vehiculo) REFERENCES Vehiculo(ID_Vehiculo),
    FOREIGN KEY (ID_Operario) REFERENCES Operario(ID_Operario)
);

CREATE TABLE Incidencia (
    ID_Incidencia INT PRIMARY KEY,
    ID_Entrega INT,
    Tipo NVARCHAR(100),
    Descripcion NVARCHAR(255),
    FechaRegistro DATETIME,
    FOREIGN KEY (ID_Entrega) REFERENCES Entrega(ID_Entrega)
);
-- 3. Crear vista para KPIs
-- 9. KPI - Entregas conformes por zona (vw_EntregasConformes)


CREATE VIEW vw_EntregasConformes AS
SELECT
    Zona,
    COUNT(*) AS TotalEntregas,
    SUM(CASE WHEN RecibidoConforme = 'Sí' THEN 1 ELSE 0 END) AS EntregasOK,
    CAST(SUM(CASE WHEN RecibidoConforme = 'Sí' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeOK
FROM Entrega
GROUP BY Zona;

-- 4. Trigger para evitar productos vencidos en pedidos
CREATE TRIGGER trg_BloqueoPedidoVencido
ON DetallePedido
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Lote l ON i.ID_Lote = l.ID_Lote
        WHERE l.FechaVencimiento < GETDATE()
    )
    BEGIN
        RAISERROR('No se puede asignar un producto vencido al pedido.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

CREATE TRIGGER trg_CantidadCajaProducto --control de caja producot mayor a 0
ON Caja_Producto
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted WHERE Cantidad <= 0
    )
    BEGIN
        RAISERROR('La cantidad debe ser mayor a cero en Caja_Producto.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;


-- 5. Procedimiento para trazabilidad de lote
CREATE PROCEDURE sp_TrazabilidadLote
    @ID_Lote INT
AS
BEGIN
    SELECT p.NombreComercial, e.FechaEntrega, e.Zona
    FROM Entrega e
    JOIN Caja_Producto cp ON cp.ID_Caja = e.ID_Caja
    JOIN Lote l ON l.ID_Lote = cp.ID_Lote
    JOIN Producto p ON p.ID_Producto = l.ID_Producto
    WHERE l.ID_Lote = @ID_Lote;
END;

-- 6. Permisos básicos para seguridad
CREATE LOGIN operador WITH PASSWORD = 'Operador123';
CREATE USER operador FOR LOGIN operador;
GRANT SELECT, INSERT ON Pedido TO operador;

CREATE LOGIN auditor WITH PASSWORD = 'Auditor123';
CREATE USER auditor FOR LOGIN auditor;
GRANT SELECT ON SCHEMA :: dbo TO auditor;

-- 7. Carga de datos simulados (mínimo 10 registros por tabla)

INSERT INTO EmpresaCliente VALUES
(1, 'Laboratorio Bagó', '30712345678'),
(2, 'Roemmers', '30598765432'),
(3, 'Elea', '30654321987'),
(4, 'Pfizer', '30555123456'),
(5, 'Gador', '30444445555'),
(6, 'Bayer', '30777778888'),
(7, 'GlaxoSmithKline', '30999990001'),
(8, 'Sanofi', '30888887777'),
(9, 'Novartis', '30700001111'),
(10, 'Abbott', '30987654321');

INSERT INTO Producto VALUES
(1, 'Paracetamol 500mg', 'Cadena de frío'),
(2, 'Ibuprofeno 400mg', 'Ambiente controlado'),
(3, 'Amoxicilina 500mg', 'Cadena de frío'),
(4, 'Omeprazol 20mg', 'Ambiente controlado'),
(5, 'Loratadina 10mg', 'Temperatura ambiente'),
(6, 'Insulina', 'Refrigeración estricta'),
(7, 'Vacuna COVID-19', 'Ultra congelación'),
(8, 'Metformina 850mg', 'Ambiente controlado'),
(9, 'Aspirina 100mg', 'Ambiente controlado'),
(10, 'Levotiroxina 50mcg', 'Ambiente controlado');

INSERT INTO Lote VALUES
(1, 1, '2026-01-10', 2.0, 8.0),
(2, 2, '2025-12-15', 10.0, 25.0),
(3, 3, '2025-11-20', 2.0, 8.0),
(4, 4, '2026-06-01', 15.0, 30.0),
(5, 5, '2026-05-10', 18.0, 30.0),
(6, 6, '2025-10-10', 2.0, 8.0),
(7, 7, '2025-09-30', -70.0, -60.0),
(8, 8, '2026-03-01', 15.0, 25.0),
(9, 9, '2025-12-25', 15.0, 25.0),
(10, 10, '2026-04-15', 15.0, 25.0);

INSERT INTO Pedido VALUES
(1, 1, '2025-06-01', 'Pendiente'),
(2, 2, '2025-06-02', 'En proceso'),
(3, 3, '2025-06-03', 'Entregado'),
(4, 4, '2025-06-04', 'Pendiente'),
(5, 5, '2025-06-05', 'Entregado'),
(6, 6, '2025-06-06', 'En proceso'),
(7, 7, '2025-06-07', 'Pendiente'),
(8, 8, '2025-06-08', 'Entregado'),
(9, 9, '2025-06-09', 'Pendiente'),
(10, 10, '2025-06-10', 'En proceso');

INSERT INTO DetallePedido VALUES
(1, 1, 1, 100),
(2, 2, 2, 200),
(3, 3, 3, 150),
(4, 4, 4, 100),
(5, 5, 5, 250),
(6, 6, 6, 300),
(7, 7, 7, 100),
(8, 8, 8, 150),
(9, 9, 9, 200),
(10, 10, 10, 100);

INSERT INTO Caja VALUES
(1, 'CB001', 5.5),
(2, 'CB002', 6.0),
(3, 'CB003', 4.5),
(4, 'CB004', 7.0),
(5, 'CB005', 8.0),
(6, 'CB006', 5.0),
(7, 'CB007', 6.5),
(8, 'CB008', 4.8),
(9, 'CB009', 7.2),
(10, 'CB010', 5.9);

INSERT INTO Caja_Producto VALUES
(1, 1, 10),
(2, 2, 20),
(3, 3, 30),
(4, 4, 40),
(5, 5, 50),
(6, 6, 60),
(7, 7, 70),
(8, 8, 80),
(9, 9, 90),
(10, 10, 100);

INSERT INTO Vehiculo VALUES
(1, 'AAA123', 'Camión', 1000),
(2, 'BBB234', 'Furgón', 800),
(3, 'CCC345', 'Refrigerado', 600),
(4, 'DDD456', 'Refrigerado', 700),
(5, 'EEE567', 'Camión', 1200),
(6, 'FFF678', 'Furgón', 850),
(7, 'GGG789', 'Camión', 1100),
(8, 'HHH890', 'Furgón', 900),
(9, 'III901', 'Refrigerado', 650),
(10, 'JJJ012', 'Camión', 1300);

INSERT INTO Ruta VALUES
(1, 'Buenos Aires', 'Rosario', 5),
(2, 'Córdoba', 'Mendoza', 8),
(3, 'La Plata', 'Bahía Blanca', 7),
(4, 'Salta', 'Tucumán', 4),
(5, 'Mar del Plata', 'Necochea', 3),
(6, 'Santa Fe', 'Paraná', 2),
(7, 'Corrientes', 'Resistencia', 2),
(8, 'Posadas', 'Iguazú', 6),
(9, 'San Juan', 'San Luis', 4),
(10, 'Neuquén', 'Bariloche', 6);

INSERT INTO Operario VALUES
(1, 'Carlos Díaz', 'Chofer'),
(2, 'Laura Gómez', 'Supervisor'),
(3, 'José Pérez', 'Chofer'),
(4, 'Ana Ruiz', 'Supervisor'),
(5, 'Luis Torres', 'Chofer'),
(6, 'María López', 'Supervisor'),
(7, 'Pedro Sánchez', 'Chofer'),
(8, 'Sofía Ramírez', 'Supervisor'),
(9, 'Juan Navarro', 'Chofer'),
(10, 'Lucía Aguilar', 'Supervisor');

INSERT INTO Entrega VALUES
(1, 1, 1, 1, 1, '2025-06-10', 'Sí', 'Centro'),
(2, 2, 2, 2, 2, '2025-06-11', 'Sí', 'Norte'),
(3, 3, 3, 3, 3, '2025-06-12', 'No', 'Sur'),
(4, 4, 4, 4, 4, '2025-06-13', 'Sí', 'Centro'),
(5, 5, 5, 5, 5, '2025-06-14', 'Sí', 'Norte'),
(6, 6, 6, 6, 6, '2025-06-15', 'Sí', 'Sur'),
(7, 7, 7, 7, 7, '2025-06-16', 'No', 'Centro'),
(8, 8, 8, 8, 8, '2025-06-17', 'Sí', 'Norte'),
(9, 9, 9, 9, 9, '2025-06-18', 'Sí', 'Sur'),
(10, 10, 10, 10, 10, '2025-06-19', 'Sí', 'Centro');

INSERT INTO Incidencia VALUES
(1, 3, 'Temperatura fuera de rango', 'Producto sufrió exposición a calor', '2025-06-12 10:00'),
(2, 7, 'Falla de entrega', 'No se encontró al destinatario', '2025-06-16 14:30'),
(3, 3, 'Golpe en tránsito', 'Caja dañada en el transporte', '2025-06-12 09:15'),
(4, 7, 'Reentrega programada', 'Se reprogramó por ausencia del receptor', '2025-06-16 18:45'),
(5, 1, 'Entrega adelantada', 'Entrega realizada antes de lo previsto', '2025-06-10 08:00'),
(6, 2, 'Ruta alternativa', 'Desvío por corte en ruta principal', '2025-06-11 11:20'),
(7, 6, 'Control de temperatura OK', 'Registro correcto de conservación', '2025-06-15 16:00'),
(8, 5, 'Entrega conforme', 'Sin novedades', '2025-06-14 09:00'),
(9, 4, 'Control fallido', 'Falta de registro de temperatura', '2025-06-13 13:15'),
(10, 9, 'Entrega parcial', 'Faltante de un producto', '2025-06-18 17:40');

 --8. KPI - Nivel de cumplimiento en entregas (On Time Delivery Rate)
-- Suponemos que la fecha comprometida de entrega es la misma que la fecha del pedido (para simplificar)
-- Se consideran entregas 'a tiempo' si la fecha de entrega es igual o anterior a la fecha del pedido + 3 días 
CREATE VIEW KPI_OnTimeDeliveryRate AS
SELECT 
    ec.Nombre AS Cliente,
    COUNT(e.ID_Entrega) AS TotalEntregas,
    SUM(CASE WHEN e.FechaEntrega <= DATEADD(DAY, 3, p.FechaPedido) THEN 1 ELSE 0 END) AS EntregasATiempo,
    CAST(
        SUM(CASE WHEN e.FechaEntrega <= DATEADD(DAY, 3, p.FechaPedido) THEN 1 ELSE 0 END) * 100.0 / COUNT(e.ID_Entrega)
        AS DECIMAL(5,2)
    ) AS PorcentajeOnTime
FROM Entrega e
JOIN Caja c ON e.ID_Caja = c.ID_Caja
JOIN Caja_Producto cp ON c.ID_Caja = cp.ID_Caja
JOIN Lote l ON cp.ID_Lote = l.ID_Lote
JOIN DetallePedido dp ON dp.ID_Lote = l.ID_Lote
JOIN Pedido p ON dp.ID_Pedido = p.ID_Pedido
JOIN EmpresaCliente ec ON p.ID_Empresa = ec.ID_Empresa
GROUP BY ec.Nombre;

-- 10. KPI - Trazabilidad completa por lote

CREATE VIEW KPI_TrazabilidadLote AS
SELECT
    l.ID_Lote,
    p.NombreComercial AS Producto,
    l.FechaVencimiento,
    ec.Nombre AS Cliente,
    ped.ID_Pedido,
    ped.FechaPedido,
    e.ID_Entrega,
    e.FechaEntrega,
    e.Zona,
    v.Patente AS Vehiculo,
    o.Nombre AS Operario
FROM Lote l
JOIN Producto p ON l.ID_Producto = p.ID_Producto
JOIN DetallePedido dp ON l.ID_Lote = dp.ID_Lote
JOIN Pedido ped ON dp.ID_Pedido = ped.ID_Pedido
JOIN EmpresaCliente ec ON ped.ID_Empresa = ec.ID_Empresa
JOIN Caja_Producto cp ON l.ID_Lote = cp.ID_Lote
JOIN Caja c ON cp.ID_Caja = c.ID_Caja
JOIN Entrega e ON c.ID_Caja = e.ID_Caja
JOIN Vehiculo v ON e.ID_Vehiculo = v.ID_Vehiculo
JOIN Operario o ON e.ID_Operario = o.ID_Operario;

-- 11. KPI - Índice de consolidación de pedidos
-- Promedio de productos distintos por cada caja enviada

CREATE VIEW KPI_IndiceConsolidacion AS
SELECT
    c.ID_Caja,
    COUNT(DISTINCT cp.ID_Lote) AS ProductosDistintos,
    ec.Nombre AS Cliente
FROM Caja c
JOIN Caja_Producto cp ON c.ID_Caja = cp.ID_Caja
JOIN Lote l ON cp.ID_Lote = l.ID_Lote
JOIN DetallePedido dp ON l.ID_Lote = dp.ID_Lote
JOIN Pedido p ON dp.ID_Pedido = p.ID_Pedido
JOIN EmpresaCliente ec ON p.ID_Empresa = ec.ID_Empresa
GROUP BY c.ID_Caja, ec.Nombre;

-- 12. KPI - Utilización de flota
-- % de ocupación promedio de los vehículos utilizados por zona y tipo

CREATE VIEW KPI_UtilizacionFlota AS
SELECT
    e.Zona,
    v.Tipo,
    AVG(c.Peso / NULLIF(v.CapacidadKg, 0)) * 100 AS PorcentajeOcupacionPromedio
FROM Entrega e
JOIN Vehiculo v ON e.ID_Vehiculo = v.ID_Vehiculo
JOIN Caja c ON e.ID_Caja = c.ID_Caja
GROUP BY e.Zona, v.Tipo;

-- 13. KPI - Incidencias por error de lote
-- Suponemos que los errores de lote se registran como tipo específico de incidencia

CREATE VIEW KPI_IncidenciasErrorLote AS
SELECT
    l.ID_Lote,
    p.NombreComercial,
    COUNT(i.ID_Incidencia) AS CantidadErroresLote
FROM Incidencia i
JOIN Entrega e ON i.ID_Entrega = e.ID_Entrega
JOIN Caja c ON e.ID_Caja = c.ID_Caja
JOIN Caja_Producto cp ON c.ID_Caja = cp.ID_Caja
JOIN Lote l ON cp.ID_Lote = l.ID_Lote
JOIN Producto p ON l.ID_Producto = p.ID_Producto
WHERE i.Tipo LIKE '%error de lote%'
GROUP BY l.ID_Lote, p.NombreComercial;

--ver tablas
SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

--ver vistas
SELECT * 
FROM INFORMATION_SCHEMA.VIEWS;
