classdef AppRodillos < handle
    properties (Access = private)
        % --- INTERFAZ GRÁFICA ---
        Figura
        PnlPlanta
        PnlSimulacion
        
        % Controles Planta
        BotonStartMotor
        LabelEstadoMotor
        InputRef
        InputPeso
        BotonAddCaja
        ListaCajas
        BotonRemCaja
        LabelMasaTotal
        
        % Controles Simulación
        BotonSimulacion
        
        % Ejes y Líneas
        AxRodillo
        AxCinta
        AxControl 
        AxAnimacion
        LineaWRodillo
        LineaVRef
        LineaVReal
        LineaVSens
        LineaFrecuencia 
        TformRodillo
        TformMotor
        
        % --- OBJETOS FÍSICOS (POO) ---
        motor
        cinta
        rodillo
        sensor
        variador
        control
        
        % --- MOTOR DE SIMULACIÓN Y RENDERIZADO ---
        MiTimer
        dt = 1/240;  %240HZ de integración     
        fps_periodo = 1/24; %24 fps de render    
        pasos_por_frame;          
        t_actual = 0;      
        
        % --- ESTADOS LÓGICOS ---
        motor_encendido = false;   
        simulacion_activa = false; 
        array_pesos = []; 
        
        % --- MEMORIA GRÁFICA ---
        hist_t = zeros(1, 500);
        hist_w_rod = zeros(1, 500);
        hist_v_real = zeros(1, 500);
        hist_v_sens = zeros(1, 500);
        hist_v_ref = zeros(1, 500);
        hist_frec = zeros(1, 500); % Array para el historial del PID
    end
    
    methods
        function app = AppRodillos()
            % Dibujamos todo lo visual
            app.crear_interfaz_grafica();
            
            % Cargamos las clases de física
            [app.motor, app.cinta, app.rodillo, app.sensor, app.variador, app.control] = Inicializar();
            app.pasos_por_frame = round(app.fps_periodo / app.dt);
            
            % Se deja el timer preparado en memoria, apagado
            app.MiTimer = timer('ExecutionMode', 'fixedRate', ...
                                'Period', app.fps_periodo, ...
                                'TimerFcn', @(~,~) app.bucle_principal());
        end
        
        function delete(app)
            % Matamos el timer a mano al cerrar para no saturar la RAM
            if isa(app.MiTimer, 'timer') && isvalid(app.MiTimer)
                stop(app.MiTimer);
                delete(app.MiTimer);
            end
            delete(app.Figura);
        end
    end
    
    methods (Access = private)
        
        function crear_interfaz_grafica(app)
            % uifigure es la ventana base
            app.Figura = uifigure('Name', 'Proyecto Mecatrónica - Daniel Jiménez Soler', ...
                                  'Position', [100, 100, 1050, 650], ...
                                  'Color', [0.94 0.94 0.94], ...
                                  'CloseRequestFcn', @(~,~) app.delete());
                                  
            uilabel(app.Figura, 'Text', 'Autor: Daniel Jiménez Soler | Ingeniería Informática y Tecnologías Virtuales', ...
                    'Position', [450, 10, 580, 20], 'FontColor', [0.4 0.4 0.4], ...
                    'FontWeight', 'bold', 'HorizontalAlignment', 'right');

            % -------------------------------------------------------------
            % PANEL PLANTA (Izquierda)
            % -------------------------------------------------------------
            app.PnlPlanta = uipanel(app.Figura, 'Title', 'Centro de Mando Planta', ...
                                    'Position', [20, 40, 240, 590], 'FontWeight', 'bold');
            
            app.BotonStartMotor = uibutton(app.PnlPlanta, 'push', 'Text', 'START MOTOR', ...
                                      'Position', [20, 520, 200, 45], ...
                                      'BackgroundColor', [0.2 0.8 0.2], ...
                                      'FontWeight', 'bold', 'FontSize', 14, ...
                                      'ButtonPushedFcn', @(~,~) app.cb_start_motor());
                                      
            app.LabelEstadoMotor = uilabel(app.PnlPlanta, 'Text', 'Motor: APAGADO', ...
                                      'Position', [20, 490, 200, 20], ...
                                      'FontColor', [1 0 0], 'FontWeight', 'bold', ...
                                      'HorizontalAlignment', 'center');
                                      
            uilabel(app.PnlPlanta, 'Text', 'Velocidad Ref (m/s):', 'Position', [20, 455, 200, 20], 'HorizontalAlignment', 'center');
            app.InputRef = uiknob(app.PnlPlanta, 'discrete', 'Position', [90, 380, 60, 60]);
            app.InputRef.Items = {'0', '1', '2', '3', '4', '5'};
            app.InputRef.ItemsData = [0, 1, 2, 3, 4, 5];
            app.InputRef.Value = 1;
            
            uilabel(app.PnlPlanta, 'Text', 'Peso nueva caja (kg):', 'Position', [20, 345, 200, 20]);
            app.InputPeso = uieditfield(app.PnlPlanta, 'numeric', 'Position', [20, 310, 200, 30]);
            app.InputPeso.Value = 2.0; 
            
            app.BotonAddCaja = uibutton(app.PnlPlanta, 'push', 'Text', 'Añadir Caja', ...
                                     'Position', [20, 260, 200, 35], ...
                                     'BackgroundColor', [0.3 0.6 0.9], 'FontColor', 'w', ...
                                     'FontWeight', 'bold', ...
                                     'ButtonPushedFcn', @(~,~) app.cb_add_caja());
                                     
            uilabel(app.PnlPlanta, 'Text', 'Cajas en tránsito:', 'Position', [20, 230, 200, 20]);
            app.ListaCajas = uilistbox(app.PnlPlanta, 'Position', [20, 85, 200, 140]);
            app.ListaCajas.Items = {};
            
            app.BotonRemCaja = uibutton(app.PnlPlanta, 'push', 'Text', 'Quitar seleccionada', ...
                                     'Position', [20, 45, 200, 30], ...
                                     'BackgroundColor', [0.9 0.3 0.3], 'FontColor', 'w', ...
                                     'ButtonPushedFcn', @(~,~) app.cb_rem_caja());
                                     
            app.LabelMasaTotal = uilabel(app.PnlPlanta, 'Text', 'Masa Total: 5.00 kg', ...
                                      'Position', [20, 10, 200, 25], ...
                                      'FontColor', [0.5 0 0.5], 'FontWeight', 'bold', ...
                                      'FontSize', 14, 'HorizontalAlignment', 'center');

            % -------------------------------------------------------------
            % PANEL SIMULACIÓN (Abajo a la derecha)
            % -------------------------------------------------------------
            app.PnlSimulacion = uipanel(app.Figura, 'Title', 'Centro de Mando Simulacion', ...
                                        'Position', [280, 40, 750, 80], 'FontWeight', 'bold');
                                        
            app.BotonSimulacion = uibutton(app.PnlSimulacion, 'push', 'Text', 'START SIMULACION', ...
                                      'Position', [20, 10, 710, 40], ...
                                      'BackgroundColor', [0.2 0.8 0.2], ...
                                      'FontWeight', 'bold', 'FontSize', 14, ...
                                      'ButtonPushedFcn', @(~,~) app.cb_start_simulacion());

            % -------------------------------------------------------------
            % LAS 3 GRÁFICAS Y LA ANIMACIÓN
            % -------------------------------------------------------------
            % Eje 1: Rodillo (Arriba, acortado para hacer hueco)
            app.AxRodillo = uiaxes(app.Figura, 'Position', [280, 390, 520, 240]);
            title(app.AxRodillo, 'Velocidad Angular del Rodillo (\omega)');
            ylabel(app.AxRodillo, 'Velocidad (rad/s)');
            grid(app.AxRodillo, 'on');
            hold(app.AxRodillo, 'on');
            app.LineaWRodillo = plot(app.AxRodillo, NaN, NaN, 'Color', [0.85 0.32 0.09], 'LineWidth', 2);
            
            % Eje Animación Rodillo (Arriba derecha)
            app.AxAnimacion = uiaxes(app.Figura, 'Position', [810, 390, 220, 240]);
            title(app.AxAnimacion, 'Posición Angular del Rodillo');
            axis(app.AxAnimacion, 'equal');
            xlim(app.AxAnimacion, [-1.5, 1.5]);
            ylim(app.AxAnimacion, [-2.5, 1.5]);
            app.AxAnimacion.XColor = 'none';
            app.AxAnimacion.YColor = 'none';
            app.AxAnimacion.Toolbar.Visible = 'off';
            disableDefaultInteractivity(app.AxAnimacion);
            hold(app.AxAnimacion, 'on');
            
            % --- DISEÑO CHULO DEL RODILLO (Polea Industrial) ---
            t = linspace(0, 2*pi, 60);
            
            % Correa de transmisión (dibuja la línea estática)
            plot(app.AxAnimacion, [-1.0, -0.4], [0, -1.8], 'k-', 'LineWidth', 2);
            plot(app.AxAnimacion, [1.0, 0.4], [0, -1.8], 'k-', 'LineWidth', 2);
            
            % Soporte estático oscuro de fondo (Rodillo)
            patch(app.AxAnimacion, 1.15*cos(t), 1.15*sin(t), [0.2 0.2 0.2], 'EdgeColor', 'none');
            
            % Creamos grupos de transformación geométrica para girar
            app.TformRodillo = hgtransform('Parent', app.AxAnimacion);
            
            % Rueda principal Rodillo
            patch('Parent', app.TformRodillo, 'XData', cos(t), 'YData', sin(t), 'FaceColor', [0.7 0.7 0.75], 'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 2);
            
            % Eje central Rodillo
            patch('Parent', app.TformRodillo, 'XData', 0.25*cos(t), 'YData', 0.25*sin(t), 'FaceColor', [0.15 0.15 0.15]);
            
            % 3 Perforaciones grandes Rodillo
            for i = 1:3
                ang = i * (2*pi/3) + pi/6;
                xc = 0.55 * cos(ang);
                yc = 0.55 * sin(ang);
                patch('Parent', app.TformRodillo, 'XData', xc + 0.25*cos(t), 'YData', yc + 0.25*sin(t), 'FaceColor', [0.2 0.2 0.2], 'EdgeColor', 'none');
            end
            
            % Indicador de posición Rodillo
            patch('Parent', app.TformRodillo, 'XData', 0.85 + 0.1*cos(t), 'YData', 0 + 0.1*sin(t), 'FaceColor', [1 0.5 0], 'EdgeColor', 'k');
            
            % --- DISEÑO DEL MOTOR (Abajo) ---
            % Soporte base
            patch(app.AxAnimacion, [-0.3, 0.3, 0.3, -0.3], [-2.3, -2.3, -1.8, -1.8], [0.1 0.1 0.1], 'EdgeColor', 'none');
            % Soporte circular trasero motor
            patch(app.AxAnimacion, 0.45*cos(t), -1.8 + 0.45*sin(t), [0.15 0.15 0.15], 'EdgeColor', 'none');
            
            % Creamos el grupo de transformación del motor (DESPUÉS del fondo para que dibuje por encima)
            app.TformMotor = hgtransform('Parent', app.AxAnimacion);
            
            % Colocamos el motor en su posición inicial (desplazado hacia abajo)
            app.TformMotor.Matrix = makehgtform('translate', [0, -1.8, 0]);
            
            % Rueda del motor
            patch('Parent', app.TformMotor, 'XData', 0.4*cos(t), 'YData', 0.4*sin(t), 'FaceColor', [0.85 0.32 0.09], 'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 1.5);
            % Marca del motor (Blanca para que resalte mucho al girar)
            patch('Parent', app.TformMotor, 'XData', 0.22 + 0.12*cos(t), 'YData', 0 + 0.12*sin(t), 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 1);
            
            % Eje 2: Cinta (Abajo izquierda)
            app.AxCinta = uiaxes(app.Figura, 'Position', [280, 130, 365, 250]);
            title(app.AxCinta, 'Velocidad Lineal de la Cinta (v)');
            xlabel(app.AxCinta, 'Tiempo (s)');
            ylabel(app.AxCinta, 'Velocidad (m/s)');
            grid(app.AxCinta, 'on');
            hold(app.AxCinta, 'on');
            
            app.LineaVRef = plot(app.AxCinta, NaN, NaN, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Referencia');
            app.LineaVReal = plot(app.AxCinta, NaN, NaN, 'b', 'LineWidth', 2, 'DisplayName', 'Real');
            app.LineaVSens = plot(app.AxCinta, NaN, NaN, 'r', 'LineWidth', 1, 'DisplayName', 'Sensor');
            legend(app.AxCinta, 'Location', 'southeast');
            
            % Eje 3: PID (Abajo derecha)
            app.AxControl = uiaxes(app.Figura, 'Position', [665, 130, 365, 250]);
            title(app.AxControl, 'Señal de Control (PID)');
            xlabel(app.AxControl, 'Tiempo (s)');
            ylabel(app.AxControl, 'Frecuencia (Hz)');
            grid(app.AxControl, 'on');
            hold(app.AxControl, 'on');
            app.LineaFrecuencia = plot(app.AxControl, NaN, NaN, 'm', 'LineWidth', 2); 
        end
        
        % =================================================================
        % FUNCIONES DE LOS BOTONES
        % =================================================================
        
        function cb_start_simulacion(app)
            if app.simulacion_activa
                app.simulacion_activa = false;
                stop(app.MiTimer); 
                app.BotonSimulacion.Text = 'START SIMULACION';
                app.BotonSimulacion.BackgroundColor = [0.2 0.8 0.2];
            else
                app.simulacion_activa = true;
                start(app.MiTimer); 
                app.BotonSimulacion.Text = 'STOP SIMULACION';
                app.BotonSimulacion.BackgroundColor = [0.8 0.2 0.2];
            end
        end
        
        function cb_start_motor(app)
            if app.motor_encendido
                app.motor_encendido = false;
                app.BotonStartMotor.Text = 'START MOTOR';
                app.BotonStartMotor.BackgroundColor = [0.2 0.8 0.2];
                app.LabelEstadoMotor.Text = 'Motor: APAGADO';
                app.LabelEstadoMotor.FontColor = [1 0 0];
            else
                app.motor_encendido = true;
                app.BotonStartMotor.Text = 'STOP MOTOR';
                app.BotonStartMotor.BackgroundColor = [0.8 0.2 0.2];
                app.LabelEstadoMotor.Text = 'Motor: GIRANDO';
                app.LabelEstadoMotor.FontColor = [0 0.7 0];
            end
        end
        
        function cb_add_caja(app)
            peso = app.InputPeso.Value;
            if peso <= 0, return; end
            
            app.cinta.ColocarCaja(peso);
            app.array_pesos(end+1) = peso;
            app.actualizar_ui_cajas();
        end
        
        function cb_rem_caja(app)
            idx = app.ListaCajas.Value;
            if isempty(idx), return; end
            
            peso = app.array_pesos(idx);
            app.cinta.QuitarCaja(peso);
            app.array_pesos(idx) = [];
            app.actualizar_ui_cajas();
        end
        
        function actualizar_ui_cajas(app)
            % Regenera la lista visual
            if isempty(app.array_pesos)
                app.ListaCajas.Items = {};
                app.ListaCajas.ItemsData = [];
            else
                nombres = cell(1, length(app.array_pesos));
                for i = 1:length(app.array_pesos)
                    nombres{i} = sprintf('Caja %d (%.1f kg)', i, app.array_pesos(i));
                end
                app.ListaCajas.Items = nombres;
                app.ListaCajas.ItemsData = 1:length(app.array_pesos);
            end
            
            app.LabelMasaTotal.Text = sprintf('Masa Total: %.2f kg', app.cinta.MasaTotal);
            if app.cinta.MasaTotal >= 15
                app.LabelMasaTotal.FontColor = [1 0 0]; % Aviso de stall visual
            else
                app.LabelMasaTotal.FontColor = [0.5 0 0.5];
            end
        end
        
        % =================================================================
        % BUCLE DEL TIMER (FÍSICA + RENDER)
        % =================================================================
        function bucle_principal(app)
            for i = 1:app.pasos_por_frame
                app.t_actual = app.t_actual + app.dt;
                
                app.sensor.Medir(app.cinta, app.dt);
                
                if app.motor_encendido
                    app.control.Referencia = app.InputRef.Value;
                    app.control.error(app.sensor.VelocidadMedida);
                    app.control.integral(app.dt);
                    app.control.derivada(app.dt);
                    frec_pedida = app.control.PID(app.dt);
                else
                    frec_pedida = 0;
                    app.control.Integral = 0;
                    app.control.Error_anterior = 0;
                end
                
                app.variador.VariadorDeFrecuencia(app.motor, frec_pedida, app.dt);
                app.motor.actualizarEstado(app.dt);
                
                app.rodillo.ActualizarEstado(app.dt);
                app.cinta.ActualizarEstado(app.rodillo);
                
                % Ruedan los arrays
                app.hist_t = [app.hist_t(2:end), app.t_actual];
                app.hist_w_rod = [app.hist_w_rod(2:end), app.rodillo.VelocidadRodillo];
                app.hist_v_real = [app.hist_v_real(2:end), app.cinta.VelocidadCinta];
                app.hist_v_sens = [app.hist_v_sens(2:end), app.sensor.VelocidadMedida];
                app.hist_frec = [app.hist_frec(2:end), frec_pedida]; 
                
                if app.motor_encendido
                    app.hist_v_ref = [app.hist_v_ref(2:end), app.control.Referencia];
                else
                    app.hist_v_ref = [app.hist_v_ref(2:end), 0];
                end
            end
            
            % Inyectamos datos
            app.LineaWRodillo.XData = app.hist_t;
            app.LineaWRodillo.YData = app.hist_w_rod;
            
            app.LineaVRef.XData = app.hist_t;
            app.LineaVRef.YData = app.hist_v_ref;
            app.LineaVReal.XData = app.hist_t;
            app.LineaVReal.YData = app.hist_v_real;
            app.LineaVSens.XData = app.hist_t;
            app.LineaVSens.YData = app.hist_v_sens;
            
            app.LineaFrecuencia.XData = app.hist_t;
            app.LineaFrecuencia.YData = app.hist_frec;
            
            % Actualizar la animación de posición con hgtransform
            theta_rodillo = app.rodillo.PosicionAngular;
            app.TformRodillo.Matrix = makehgtform('zrotate', theta_rodillo);
            
            theta_motor = app.motor.PosicionAngular;
            app.TformMotor.Matrix = makehgtform('translate', [0, -1.8, 0]) * makehgtform('zrotate', theta_motor);
            
            % Autoescala ejes
            lim_ref = max(1, app.InputRef.Value * 1.5);
            ylim(app.AxCinta, [0, lim_ref]);
            xlim(app.AxCinta, [app.hist_t(1), max(1, app.hist_t(end))]);
            
            ylim(app.AxRodillo, [0, (lim_ref / app.rodillo.RadioEfectivo)]);
            xlim(app.AxRodillo, [app.hist_t(1), max(1, app.hist_t(end))]);
            
            ylim(app.AxControl, [-5, app.control.Max + 5]);
            xlim(app.AxControl, [app.hist_t(1), max(1, app.hist_t(end))]);
            
            drawnow limitrate;
        end
    end
end