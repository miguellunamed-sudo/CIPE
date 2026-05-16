-- 1. Insertamos un proveedor y una ubicación para tener los datos completos
INSERT INTO proveedores (nombre, telefono, direccion) 
VALUES ('Papelería Mayorista', '341-000-0000', 'Centro, Ciudad Guzmán');

INSERT INTO ubicaciones (descripcion) 
VALUES ('Anaquel Principal - Cuadernos');

-- 2. Registramos el producto (Observa que NO estamos escribiendo el precio_venta)
INSERT INTO productos (nombre, codigo_barras, precio_compra, stock_actual, id_proveedor, id_ubicacion) 
VALUES ('Cuaderno Profesional Raya 100 hojas', '1234567890123', 50.00, 15, 1, 1);


-- 3. Consultamos la tabla para ver la magia
SELECT nombre, precio_compra, margen_ganancia, precio_venta 
FROM productos;

