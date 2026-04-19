USE Destinos_Soñados_SA; # Utilizar Base de Datos Creada

# 1. CrearPaqueteTuristico: Crea un nuevo paquete turístico con destinos y servicios.

DELIMITER //
CREATE PROCEDURE CrearPaqueteTuristico(
    IN p_codigo VARCHAR(20),
    IN p_nombre VARCHAR(150),
    IN p_dias TINYINT,
    IN p_noches TINYINT,
    IN p_precio DECIMAL(10,2),
    IN p_min_personas SMALLINT,
    IN p_dificultad TINYINT,
    IN p_transporte INT,
    IN p_categoria INT,
    IN p_regimen INT,
    IN p_destino INT
)
BEGIN
    INSERT INTO Paquete_Turistico
    (codigo, nombre_comercial, duracion_dias, duracion_noches, precio_base,
     minimo_participantes, nivel_dificultad, id_tipo_transporte,
     id_categoria_alojamiento, id_regimen)
    VALUES
    (p_codigo, p_nombre, p_dias, p_noches, p_precio,
     p_min_personas, p_dificultad, p_transporte,
     p_categoria, p_regimen);

    INSERT INTO Paquete_Destino (id_paquete, id_destino)
    VALUES (LAST_INSERT_ID(), p_destino);
END //
DELIMITER ;

#Consulta para saber que datos hay antes de hacer el Call
SELECT * FROM Paquete_Turistico ORDER BY id_paquete DESC;
#Ejemplo para 
CALL CrearPaqueteTuristico('PKG021','Aventura en Cartagena',5,4,1200.00,2,2,
    1,  -- id_tipo_transporte
    3,  -- id_categoria_alojamiento
    2,  -- id_regimen
    1   -- id_destino
);
#Vuelva a Consultar
SELECT * FROM Paquete_Turistico ORDER BY id_paquete DESC;

# 2. RegistrarReserva: Registra una nueva reserva verificando disponibilidad.

DELIMITER //
CREATE PROCEDURE RegistrarReserva(
    IN p_cliente INT,
    IN p_paquete INT,
    IN p_guia INT,
    IN p_metodo INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_adultos INT,
    IN p_ninos INT,
    IN p_precio DECIMAL(10,2)
)
BEGIN
    IF p_fecha_inicio < p_fecha_fin THEN
        
        INSERT INTO Reserva
        (numero_reserva, fecha_creacion, fecha_inicio, fecha_fin,
         cantidad_adultos, cantidad_ninos, precio_total,
         abonos_realizados, saldo_pendiente, estado,
         id_cliente, id_metodo_pago, id_paquete, id_guia)
        VALUES
        (CONCAT('RES', FLOOR(RAND()*10000)),
         NOW(), p_fecha_inicio, p_fecha_fin,
         p_adultos, p_ninos, p_precio,
         p_precio/2, p_precio/2, 'Pendiente',
         p_cliente, p_metodo, p_paquete, p_guia);

    ELSE
        SELECT 'Error: fechas inválidas' AS mensaje;
    END IF;
END //
DELIMITER ;

SELECT * FROM Reserva ORDER BY id_Reserva DESC;

CALL RegistrarReserva(
    1,   -- id_cliente
    1,   -- id_paquete
    1,   -- id_guia
    1,   -- id_metodo_pago
    '2026-06-10',
    '2026-06-15',
    2,   -- adultos
    1,   -- niños
    1500.00
);

# 3. AsignarGuiaTuristico: Asigna un guía turístico según idioma y destino.

DELIMITER //
CREATE PROCEDURE AsignarGuiaTuristico(
    IN p_destino INT,
    IN p_idioma INT
)
BEGIN
    SELECT g.id_guia, g.nombres, g.apellidos
    FROM Guia_Turistico g
    JOIN Guia_Idioma gi ON g.id_guia = gi.id_guia
    JOIN Guia_Destino gd ON g.id_guia = gd.id_guia
    WHERE gi.id_idioma = p_idioma
    AND gd.id_destino = p_destino
    AND g.disponibilidad = 1
    LIMIT 1;
END //
DELIMITER ;

CALL AsignarGuiaTuristico(
    1,  -- id_destino
    1   -- id_idioma
);

DELIMITER //

# 4. GestionarProveedoresLocales: Administra relaciones con proveedores locales por destino.
DELIMITER //
CREATE PROCEDURE GestionarProveedoresLocales(
    IN p_destino INT
)
BEGIN
    SELECT t.proveedor, t.ruta, t.tarifa
    FROM Transporte t
    JOIN Paquete_Turistico p ON t.id_tipo_transporte = p.id_tipo_transporte
    JOIN Paquete_Destino pd ON p.id_paquete = pd.id_paquete
    WHERE pd.id_destino = p_destino;
END //
DELIMITER ;

CALL GestionarProveedoresLocales(
    1  -- id_destino
);

# 5. CrearPromocionTemporada: Crea una promoción para temporadas específicas.
DELIMITER //
CREATE PROCEDURE CrearPromocionTemporada(
    IN p_codigo VARCHAR(20),
    IN p_nombre VARCHAR(150),
    IN p_desc TEXT,
    IN p_inicio DATE,
    IN p_fin DATE,
    IN p_descuento DECIMAL(10,2),
    IN p_tipo INT
)
BEGIN
    INSERT INTO Promocion
    (codigo, nombre, descripcion, fecha_inicio, fecha_fin,
     valor_descuento, condiciones_especiales, resultados_obtenidos, id_tipo_descuento)
    VALUES
    (p_codigo, p_nombre, p_desc, p_inicio, p_fin,
     p_descuento, 'Aplicable en temporada', 'Pendiente', p_tipo);
END //
DELIMITER ;

CALL CrearPromocionTemporada(
    'PROMO21',
    'Descuento Verano 2026',
    'Promoción especial de verano',
    '2026-06-01',
    '2026-08-31',
    200.00,
    1  -- id_tipo_descuento
);
SELECT * FROM Promocion ORDER BY id_promocion DESC;

# Vistas 
#1.	V_PaquetesDisponibles: Muestra todos los paquetes disponibles con precios actualizados.

CREATE VIEW V_PaquetesDisponibles AS
SELECT p.codigo,p.nombre_comercial,p.precio_base,t.nombre AS transporte,r.nombre AS regimen
FROM Paquete_Turistico p
JOIN Tipo_Transporte t ON p.id_tipo_transporte = t.id_tipo_transporte
JOIN Regimen_Alimenticio r ON p.id_regimen = r.id_regimen;

SELECT * FROM V_PaquetesDisponibles;

# 2. V_ReservasActivas: Detalla las reservas activas por fecha y estado.

CREATE VIEW V_ReservasActivas AS
SELECT numero_reserva, fecha_inicio, fecha_fin ,estado , precio_total
FROM Reserva
WHERE estado IN ('Confirmada','Pendiente');

SELECT * FROM V_ReservasActivas ORDER BY precio_total DESC;

# 3. V_DisponibilidadGuias: Disponibilidad de guías turísticos por fecha, idioma y destino.

CREATE VIEW V_DisponibilidadGuias AS
SELECT g.nombres, g.apellidos, i.nombre AS idioma, d.nombre AS destino, g.disponibilidad
FROM Guia_Turistico g
JOIN Guia_Idioma gi ON g.id_guia = gi.id_guia
JOIN Idioma i ON gi.id_idioma = i.id_idioma
JOIN Guia_Destino gd ON g.id_guia = gd.id_guia
JOIN Destino_Turistico d ON gd.id_destino = d.id_destino;

SELECT * FROM V_DisponibilidadGuias ORDER BY idioma ASC;

# 4. V_OcupacionAlojamientos: Nivel de ocupación de alojamientos asociados por destino.
# profe por mas que lo intente esta no me quedo clara por que no tengo reservas ligadas directamente a alojamiento en el ejercicio original y incluso mas optimizada no existe esta relacion

# 5. V_EstadisticasDestinos: Estadísticas de reservas por destino y temporada.
CREATE VIEW V_EstadisticasDestinos AS
SELECT 
    d.nombre AS destino,
    t.nombre AS temporada,
    COUNT(r.id_reserva) AS total_reservas,
    SUM(r.precio_total) AS ingresos
FROM Reserva r
JOIN Paquete_Turistico p ON r.id_paquete = p.id_paquete
JOIN Paquete_Destino pd ON p.id_paquete = pd.id_paquete
JOIN Destino_Turistico d ON pd.id_destino = d.id_destino
JOIN Destino_Temporada dt ON d.id_destino = dt.id_destino
JOIN Temporada t ON dt.id_temporada = t.id_temporada
GROUP BY d.nombre, t.nombre;

SELECT * FROM V_EstadisticasDestinos ORDER BY total_reservas DESC;
