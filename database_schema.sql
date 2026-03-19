-- sql/database_schema.sql
-- Sistema de Cálculo de Prestaciones Sociales y Fideicomiso
-- Basado en LOTTT Artículo 142 [[51]] y tasas BCV [[59]]

CREATE DATABASE IF NOT EXISTS sistema_prestaciones CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sistema_prestaciones;

-- ============================================
-- TABLA: CONFIGURACIÓN DEL ENTE PÚBLICO
-- ============================================
CREATE TABLE configuracion_ente (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_ente VARCHAR(255) NOT NULL,
    rif VARCHAR(20) NOT NULL,
    direccion TEXT,
    telefono VARCHAR(50),
    email VARCHAR(100),
    logo_path VARCHAR(255),
    nombre_alcaldia VARCHAR(255),
    nombre_fundacion VARCHAR(255),
    departamento VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: EMPLEADOS
-- ============================================
CREATE TABLE empleados (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cedula VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    cargo VARCHAR(150),
    tipo_personal ENUM('OBRERO', 'EMPLEADO', 'DIRECTIVO') DEFAULT 'EMPLEADO',
    fecha_ingreso DATE NOT NULL,
    fecha_egreso DATE,
    motivo_egreso VARCHAR(100),
    salario_mensual DECIMAL(15,2) DEFAULT 0,
    prima_antiguedad DECIMAL(15,2) DEFAULT 0,
    prima_profesional DECIMAL(15,2) DEFAULT 0,
    prima_por_hijos DECIMAL(15,2) DEFAULT 0,
    hijos_cantidad INT DEFAULT 0,
    fecha_inicio_prima_hijos DATE,
    estatus ENUM('ACTIVO', 'EGRESADO') DEFAULT 'ACTIVO',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cedula (cedula),
    INDEX idx_estatus (estatus)
);

-- ============================================
-- TABLA: TASAS DE INTERÉS HISTÓRICAS (BCV)
-- ============================================
CREATE TABLE tasas_interes_historicas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    anio INT NOT NULL,
    mes INT NOT NULL,
    fecha_publicacion DATE,
    gaceta_oficial_numero VARCHAR(50),
    tasa_activa DECIMAL(10,4) NOT NULL,
    tasa_pasiva DECIMAL(10,4),
    tasa_promedio DECIMAL(10,4) NOT NULL,
    tasa_mora DECIMAL(10,4),
    reconversion_monetaria ENUM('NINGUNA', '2008', '2018', '2021') DEFAULT 'NINGUNA',
    factor_reconversion DECIMAL(20,6) DEFAULT 1.000000,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_mes_anio (anio, mes),
    INDEX idx_anio (anio)
);

-- ============================================
-- TABLA: RECONVERSIONES MONETARIAS
-- ============================================
CREATE TABLE reconversiones_monetarias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    fecha_vigencia DATE NOT NULL,
    ceros_eliminados INT NOT NULL,
    factor_conversion DECIMAL(20,6) NOT NULL,
    moneda_anterior VARCHAR(50),
    moneda_nueva VARCHAR(50),
    gaceta_oficial_numero VARCHAR(50),
    decreto_numero VARCHAR(50),
    observaciones TEXT
);

-- ============================================
-- TABLA: HISTORIAL SALARIAL EMPLEADOS
-- ============================================
CREATE TABLE historial_salarial (
    id INT PRIMARY KEY AUTO_INCREMENT,
    empleado_id INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    salario_base DECIMAL(15,2) NOT NULL,
    salario_integral DECIMAL(15,2),
    bono_vacacional DECIMAL(15,2) DEFAULT 0,
    bono_fin_anio DECIMAL(15,2) DEFAULT 0,
    bono_alimentacion DECIMAL(15,2) DEFAULT 0,
    otros_bonos DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (empleado_id) REFERENCES empleados(id) ON DELETE CASCADE,
    INDEX idx_empleado_fecha (empleado_id, fecha_inicio)
);

-- ============================================
-- TABLA: CÁLCULOS DE PRESTACIONES
-- ============================================
CREATE TABLE calculos_prestaciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    empleado_id INT NOT NULL,
    fecha_calculo DATE NOT NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_egreso DATE NOT NULL,
    tiempo_servicio_anios INT,
    tiempo_servicio_meses INT,
    tiempo_servicio_dias INT,
    salario_mensual DECIMAL(15,2),
    salario_diario DECIMAL(15,2),
    salario_integral DECIMAL(15,2),
    -- Prestaciones Sociales
    prestaciones_sociales_art142_ab DECIMAL(15,2),
    intereses_garantia_prestaciones DECIMAL(15,2),
    -- Otros Beneficios
    fraccion_bono_vacacional DECIMAL(15,2),
    fraccion_bono_fin_anio DECIMAL(15,2),
    vacaciones_no_disfrutadas DECIMAL(15,2),
    fraccion_sueldos DECIMAL(15,2),
    fraccion_bono_alimentacion DECIMAL(15,2),
    -- Totales
    total_asignaciones DECIMAL(15,2),
    deducciones DECIMAL(15,2),
    total_pagar DECIMAL(15,2),
    -- Cálculo Artículo 142 Literal C
    prestaciones_30_dias DECIMAL(15,2),
    garantia_depositada DECIMAL(15,2),
    menos_depositos_banco DECIMAL(15,2),
    menos_anticipos DECIMAL(15,2),
    total_general_142c DECIMAL(15,2),
    -- Usuario que realizó el cálculo
    usuario_responsable VARCHAR(100),
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (empleado_id) REFERENCES empleados(id) ON DELETE CASCADE,
    INDEX idx_empleado_fecha (empleado_id, fecha_calculo)
);

-- ============================================
-- TABLA: CÁLCULOS DE FIDEICOMISO
-- ============================================
CREATE TABLE calculos_fideicomiso (
    id INT PRIMARY KEY AUTO_INCREMENT,
    empleado_id INT NOT NULL,
    fecha_calculo DATE NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    -- Datos del empleado
    salario_base DECIMAL(15,2),
    alicuota_bono_vacacional DECIMAL(15,2),
    alicuota_aguinaldo DECIMAL(15,2),
    salario_integral DECIMAL(15,2),
    -- Cálculos mensuales (JSON con detalle)
    detalle_mensual JSON,
    -- Totales
    total_garantia_prestaciones DECIMAL(15,2),
    total_intereses_garantia DECIMAL(15,2),
    total_general DECIMAL(15,2),
    -- Tasas aplicadas
    tasa_activa_aplicada DECIMAL(10,4),
    tasa_promedio_aplicada DECIMAL(10,4),
    -- Usuario
    usuario_responsable VARCHAR(100),
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (empleado_id) REFERENCES empleados(id) ON DELETE CASCADE
);

-- ============================================
-- TABLA: ALÍCUOTAS MENSUALES
-- ============================================
CREATE TABLE alicuotas_mensuales (
    id INT PRIMARY KEY AUTO_INCREMENT,
    empleado_id INT NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    fecha DATE NOT NULL,
    salario_mes DECIMAL(15,2),
    dias_trabajados INT DEFAULT 30,
    alicuota_vacacional DECIMAL(15,2),
    alicuota_aguinaldo DECIMAL(15,2),
    prima_hijos DECIMAL(15,2) DEFAULT 0,
    salario_integral DECIMAL(15,2),
    garantia_trimestral DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (empleado_id) REFERENCES empleados(id) ON DELETE CASCADE,
    UNIQUE KEY unique_empleado_mes (empleado_id, anio, mes)
);

-- ============================================
-- DATOS INICIALES - RECONVERSIONES MONETARIAS
-- Basado en historia económica Venezuela [[21]], [[24]], [[30]]
-- ============================================
INSERT INTO reconversiones_monetarias (nombre, fecha_vigencia, ceros_eliminados, factor_conversion, moneda_anterior, moneda_nueva, gaceta_oficial_numero, decreto_numero) VALUES
('Primera Reconversión', '2008-01-01', 3, 0.001000, 'Bolívar', 'Bolívar Fuerte', '38.855', '5.229'),
('Segunda Reconversión', '2018-08-20', 5, 0.000010, 'Bolívar Fuerte', 'Bolívar Soberano', '41.446', '3.551'),
('Tercera Reconversión', '2021-10-01', 6, 0.000001, 'Bolívar Soberano', 'Bolívar Digital', '42.231', '4.553');

-- ============================================
-- DATOS INICIALES - TASAS DE INTERÉS (Ejemplo 2024-2025)
-- Basado en publicaciones BCV [[59]], [[66]], [[44]]
-- ============================================
INSERT INTO tasas_interes_historicas (anio, mes, fecha_publicacion, gaceta_oficial_numero, tasa_activa, tasa_pasiva, tasa_promedio, tasa_mora, reconversion_monetaria, factor_reconversion) VALUES
(2024, 1, '2024-01-15', '42.901', 45.50, 35.20, 40.35, 55.50, '2021', 1.000000),
(2024, 6, '2024-06-15', '42.950', 48.75, 37.80, 43.28, 58.75, '2021', 1.000000),
(2024, 12, '2024-12-15', '43.100', 55.20, 42.50, 48.85, 65.20, '2021', 1.000000),
(2025, 1, '2025-01-15', '43.120', 56.80, 43.90, 50.35, 66.80, '2021', 1.000000),
(2025, 6, '2025-06-15', '43.180', 58.50, 45.20, 51.85, 68.50, '2021', 1.000000),
(2025, 9, '2025-09-15', '43.220', 58.95, 45.80, 52.38, 68.95, '2021', 1.000000),
(2025, 12, '2025-12-15', '43.249', 58.95, 46.00, 52.48, 68.95, '2021', 1.000000);

-- ============================================
-- CONFIGURACIÓN INICIAL DEL ENTE
-- ============================================
INSERT INTO configuracion_ente (nombre_ente, rif, direccion, telefono, email, nombre_alcaldia, nombre_fundacion, departamento) VALUES
('FUNDACIÓN DEL NIÑO MUNICIPAL BARINAS', 'G-20000000-0', 'Calle Principal #123, Barinas, Venezuela', '0273-1234567', 'contacto@fundacionbarinas.gob.ve', 'ALCALDÍA BOLIVARIANA DEL MUNICIPIO BARINAS', 'FUNDACIÓN DEL NIÑO MUNICIPAL BARINAS', 'DEPARTAMENTO DE RECURSOS HUMANOS');
