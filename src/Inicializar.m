function [motor,cinta,rodillo,sensor,variador,control] = Inicializar()
    % Parametros
    %--------------------------------------------
    % Motor
    Ra = 2;       % Resistencia Armadura (Ohms)
    La = 0.05;    % Inductancia Armadura (Henrios)
    Bm = 0.05;    % Coeficiente de viscosidad (Nm*s/rad)
    Jm = 0.02;    % Inercia interna del motor (kg*m^2)
    K1 = 1;       % Coeficiente torque (Nm/A)
    Kb = 1;       % Constante de induccion (V*s/rad)
    P = 4;        % Polos Motor AC
    
    % Rodillo-Cinta
    RadioRodillo = 0.49; % Radio del rodillo (m)
    GrosorCinta = 0.01;  % Grosor de la cinta (m)
    RelacionTransmision = 5; % Relación de la caja reductora i (wr = wm/i)
    Muestatico = 0.5;    % Friccion estatica
    Mudinamico = 0.4;    % Friccion dinamica
    MasaCinta = 5;       % Masa de la cinta en vacio (kg)
    
    % Sensor
    tauSensor = 0.05;   % Filtro del sensor
    Ruido = 0.0001;
    Sesgo = 0.002;
    
    % Variador De Frecuencia
    tauVFD = 0.005;      % Respuesta del variador 
    
    % Referencia
    Referencia = 1.0;    % Velocidad lineal de la cinta (m/s)
    
    % Control
    % Ganancias agresivas para llegar rapido a la referencia
    kp = 20;
    ki = 50;
    kd = 3;
    
    %Parametros Saturation
    Max = 60;
    Min = 0;
    %--------------------------------------------------
    
    % Condiciones Iniciales (Corregida la sintaxis de MATLAB)
    motor = Motor(Ra, La, Bm, Jm, K1, Kb, P);
    cinta = Cinta(GrosorCinta, Muestatico, Mudinamico, MasaCinta);
    rodillo = Rodillo(motor, cinta, RadioRodillo, RelacionTransmision);
    sensor = Sensor(tauSensor,Ruido,Sesgo);
    variador = VFD(tauVFD);
    control = Control(Referencia, kp, ki, kd,Max,Min);
end