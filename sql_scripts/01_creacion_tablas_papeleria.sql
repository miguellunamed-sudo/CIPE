-- 1. BORRAR TODO LO ANTERIOR (Para empezar de cero y limpio)
DROP TABLE IF EXISTS detalle_venta CASCADE;
DROP TABLE IF EXISTS ventas CASCADE;
DROP TABLE IF EXISTS movimientos CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS ubicaciones CASCADE;
DROP TABLE IF EXISTS proveedores CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 2. CREAR TABLAS INDEPENDIENTES (Las que no dependen de nadie)
CREATE TABLE roles (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO roles (nombre) VALUES ('ADMIN'), ('EMPLEADO');

CREATE TABLE proveedores (
    id_proveedor SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT
);

CREATE TABLE ubicaciones (
    id_ubicacion SERIAL PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL
);

-- 3. CREAR TABLAS CON DEPENDENCIAS
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    contraseña TEXT NOT NULL,
    id_rol INT REFERENCES roles(id_rol) ON DELETE RESTRICT
);

CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    codigo_barras VARCHAR(100) UNIQUE,
    precio_compra NUMERIC(10,2) NOT NULL,
    margen_ganancia NUMERIC(5,2) DEFAULT 40.00,
    precio_venta NUMERIC(10,2) GENERATED ALWAYS AS (precio_compra * (1 + (margen_ganancia / 100))) STORED,
    precio_mayoreo NUMERIC(10,2),
    stock_actual INT DEFAULT 0,
    stock_minimo INT DEFAULT 5,
    id_proveedor INT REFERENCES proveedores(id_proveedor) ON DELETE SET NULL,
    id_ubicacion INT REFERENCES ubicaciones(id_ubicacion) ON DELETE SET NULL
);

CREATE TABLE movimientos (
    id_movimiento SERIAL PRIMARY KEY,
    id_producto INT REFERENCES productos(id_producto) ON DELETE RESTRICT,
    tipo VARCHAR(10) CHECK (tipo IN ('ENTRADA', 'SALIDA')),
    cantidad INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario INT REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);

CREATE TABLE ventas (
    id_venta SERIAL PRIMARY KEY,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(10,2) DEFAULT 0.00,
    id_usuario INT REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);


CREATE TABLE detalle_venta (
    id_detalle SERIAL PRIMARY KEY,
    id_venta INT REFERENCES ventas(id_venta) ON DELETE CASCADE,
    id_producto INT REFERENCES productos(id_producto) ON DELETE RESTRICT,
    cantidad INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED
);