function record_demo(outputAvi)
    % RECORD_DEMO Runs a scripted 14-second closed-loop simulation using the
    % actual MATLAB plant classes and records a 1280x720 30 fps demo video.

    if nargin < 1
        outputAvi = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'media', 'demo_raw.avi');
    end

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(repoRoot, 'src'));

    % Initialize plant using the real project factory
    [motor, cinta, rodillo, sensor, variador, control] = Inicializar();

    dt = 1 / 240;         % 240 Hz physics integration
    fps = 30;             % 30 fps video output
    substeps = round((1 / fps) / dt);  % 8 physics steps per video frame
    duration = 14.0;      % 14 seconds total
    totalFrames = round(duration * fps);

    % Dark-themed engineering dashboard figure (1280x720)
    bgDark = [0.07 0.08 0.11];
    panelDark = [0.11 0.13 0.17];
    textLight = [0.92 0.94 0.97];
    gridColor = [0.24 0.28 0.35];

    fig = figure('Visible', 'off', 'Color', bgDark, ...
                 'Position', [100, 100, 1280, 720], 'InvertHardcopy', 'off');

    % Title banner
    annotation(fig, 'textbox', [0.02, 0.935, 0.72, 0.055], ...
        'String', 'Mechatronic Conveyor Belt — Closed-Loop PID & VFD Simulation (MATLAB)', ...
        'Color', textLight, 'FontSize', 16, 'FontWeight', 'bold', ...
        'EdgeColor', 'none', 'VerticalAlignment', 'middle');

    statusBox = annotation(fig, 'textbox', [0.02, 0.885, 0.72, 0.045], ...
        'String', 'Event: Startup (Ref = 1.0 m/s | Load = 5.0 kg)', ...
        'Color', [0.30 0.82 1.00], 'FontSize', 12, 'FontWeight', 'bold', ...
        'EdgeColor', 'none', 'VerticalAlignment', 'middle');

    telemetryBox = annotation(fig, 'textbox', [0.75, 0.06, 0.23, 0.24], ...
        'String', '', 'Color', textLight, 'BackgroundColor', panelDark, ...
        'EdgeColor', [0.25 0.32 0.42], 'LineWidth', 1.2, ...
        'FontName', 'Consolas', 'FontSize', 11, 'Margin', 10);

    % Axes 1: Linear belt velocity (top-left, main plot)
    axCinta = axes(fig, 'Position', [0.06, 0.50, 0.65, 0.35], ...
                   'Color', panelDark, 'XColor', textLight, 'YColor', textLight, ...
                   'GridColor', gridColor, 'GridAlpha', 0.45);
    grid(axCinta, 'on'); hold(axCinta, 'on');
    title(axCinta, 'Conveyor Belt Linear Velocity (v)', 'Color', textLight, 'FontSize', 12);
    ylabel(axCinta, 'Velocity (m/s)', 'Color', textLight);
    lnVRef  = plot(axCinta, NaN, NaN, '--', 'Color', [0.85 0.88 0.92], 'LineWidth', 1.8, 'DisplayName', 'Reference');
    lnVReal = plot(axCinta, NaN, NaN, '-',  'Color', [0.20 0.78 1.00], 'LineWidth', 2.4, 'DisplayName', 'Actual');
    lnVSens = plot(axCinta, NaN, NaN, '-',  'Color', [1.00 0.45 0.30], 'LineWidth', 1.3, 'DisplayName', 'Sensor (filtered + noise)');
    lgd = legend(axCinta, 'Location', 'northwest', 'TextColor', textLight, 'Color', bgDark, 'EdgeColor', gridColor);
    lgd.FontSize = 9;

    % Axes 2: Roller angular velocity (bottom-left)
    axRod = axes(fig, 'Position', [0.06, 0.08, 0.30, 0.32], ...
                 'Color', panelDark, 'XColor', textLight, 'YColor', textLight, ...
                 'GridColor', gridColor, 'GridAlpha', 0.45);
    grid(axRod, 'on'); hold(axRod, 'on');
    title(axRod, 'Roller Angular Velocity (\omega_r)', 'Color', textLight, 'FontSize', 11);
    xlabel(axRod, 'Time (s)', 'Color', textLight);
    ylabel(axRod, '\omega_r (rad/s)', 'Color', textLight);
    lnWRod = plot(axRod, NaN, NaN, '-', 'Color', [0.98 0.62 0.18], 'LineWidth', 2.2);

    % Axes 3: PID frequency command (bottom-middle)
    axPid = axes(fig, 'Position', [0.41, 0.08, 0.30, 0.32], ...
                 'Color', panelDark, 'XColor', textLight, 'YColor', textLight, ...
                 'GridColor', gridColor, 'GridAlpha', 0.45);
    grid(axPid, 'on'); hold(axPid, 'on');
    title(axPid, 'PID Control Command (VFD Frequency)', 'Color', textLight, 'FontSize', 11);
    xlabel(axPid, 'Time (s)', 'Color', textLight);
    ylabel(axPid, 'Frequency (Hz)', 'Color', textLight);
    lnFreq = plot(axPid, NaN, NaN, '-', 'Color', [0.85 0.42 1.00], 'LineWidth', 2.2);

    % Axes 4: Live pulley + motor animation (top-right)
    axAnim = axes(fig, 'Position', [0.75, 0.35, 0.23, 0.55], 'Color', panelDark);
    title(axAnim, 'Gearbox (i = 5) — Roller & Motor', 'Color', textLight, 'FontSize', 11);
    axis(axAnim, 'equal');
    xlim(axAnim, [-1.45, 1.45]);
    ylim(axAnim, [-2.45, 1.35]);
    axAnim.XColor = 'none';
    axAnim.YColor = 'none';
    hold(axAnim, 'on');

    th = linspace(0, 2*pi, 64);
    % Belt lines
    plot(axAnim, [-1.0, -0.4], [0, -1.8], '-', 'Color', [0.55 0.62 0.72], 'LineWidth', 2.5);
    plot(axAnim, [ 1.0,  0.4], [0, -1.8], '-', 'Color', [0.55 0.62 0.72], 'LineWidth', 2.5);
    % Roller housing
    patch(axAnim, 1.15*cos(th), 1.15*sin(th), [0.16 0.19 0.24], 'EdgeColor', [0.35 0.40 0.48], 'LineWidth', 1.2);
    tformRod = hgtransform('Parent', axAnim);
    patch('Parent', tformRod, 'XData', cos(th), 'YData', sin(th), 'FaceColor', [0.58 0.64 0.72], 'EdgeColor', [0.22 0.25 0.30], 'LineWidth', 2);
    patch('Parent', tformRod, 'XData', 0.24*cos(th), 'YData', 0.24*sin(th), 'FaceColor', [0.12 0.14 0.18]);
    for k = 1:3
        ang = k * (2*pi/3) + pi/6;
        patch('Parent', tformRod, 'XData', 0.55*cos(ang) + 0.24*cos(th), 'YData', 0.55*sin(ang) + 0.24*sin(th), ...
              'FaceColor', [0.16 0.19 0.24], 'EdgeColor', 'none');
    end
    patch('Parent', tformRod, 'XData', 0.84 + 0.11*cos(th), 'YData', 0.11*sin(th), 'FaceColor', [0.20 0.78 1.00], 'EdgeColor', 'k');

    % Motor housing & rotor
    patch(axAnim, [-0.32, 0.32, 0.32, -0.32], [-2.32, -2.32, -1.80, -1.80], [0.14 0.17 0.22], 'EdgeColor', 'none');
    patch(axAnim, 0.46*cos(th), -1.8 + 0.46*sin(th), [0.18 0.21 0.27], 'EdgeColor', [0.35 0.40 0.48]);
    tformMot = hgtransform('Parent', axAnim);
    tformMot.Matrix = makehgtform('translate', [0, -1.8, 0]);
    patch('Parent', tformMot, 'XData', 0.40*cos(th), 'YData', 0.40*sin(th), 'FaceColor', [0.92 0.42 0.18], 'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.5);
    patch('Parent', tformMot, 'XData', 0.22 + 0.11*cos(th), 'YData', 0.11*sin(th), 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 1);

    % Video writer
    vw = VideoWriter(outputAvi, 'Motion JPEG AVI');
    vw.FrameRate = fps;
    vw.Quality = 95;
    open(vw);

    % Rolling history (last 5 seconds = 1200 physics steps)
    win = 1200;
    h_t    = nan(1, win);
    h_wrod = nan(1, win);
    h_vr   = nan(1, win);
    h_vs   = nan(1, win);
    h_vref = nan(1, win);
    h_frec = nan(1, win);

    t_sim = 0.0;
    box1Added = false;
    box2Added = false;
    boxesRemoved = false;
    eventLabel = 'Event: Startup (Ref = 1.0 m/s | Belt empty: 5.0 kg)';

    for frame = 1:totalFrames
        for s = 1:substeps
            t_sim = t_sim + dt;

            % Scripted industrial test scenario
            if t_sim < 3.0
                control.Referencia = 1.0;
            elseif t_sim < 11.5
                control.Referencia = 3.0;
                if ~box1Added && t_sim >= 3.0 && t_sim < 6.0
                    eventLabel = 'Event: Setpoint step 1.0 -> 3.0 m/s';
                end
            else
                control.Referencia = 1.5;
            end

            if ~box1Added && t_sim >= 6.0
                cinta.ColocarCaja(20.0);
                box1Added = true;
                eventLabel = 'Event: +20 kg box dropped on belt (Total: 25.0 kg)';
            end
            if ~box2Added && t_sim >= 9.0
                cinta.ColocarCaja(15.0);
                box2Added = true;
                eventLabel = 'Event: +15 kg heavy load added (Total: 40.0 kg)';
            end
            if ~boxesRemoved && t_sim >= 11.5
                cinta.QuitarCaja(35.0);
                boxesRemoved = true;
                eventLabel = 'Event: Load unloaded (5.0 kg) & Ref -> 1.5 m/s';
            end

            % Exact closed-loop step
            sensor.Medir(cinta, dt);
            control.error(sensor.VelocidadMedida);
            control.integral(dt);
            control.derivada(dt);
            frec = control.PID(dt);

            variador.VariadorDeFrecuencia(motor, frec, dt);
            motor.actualizarEstado(dt);
            rodillo.ActualizarEstado(dt);
            cinta.ActualizarEstado(rodillo);

            h_t    = [h_t(2:end), t_sim];
            h_wrod = [h_wrod(2:end), rodillo.VelocidadRodillo];
            h_vr   = [h_vr(2:end), cinta.VelocidadCinta];
            h_vs   = [h_vs(2:end), sensor.VelocidadMedida];
            h_vref = [h_vref(2:end), control.Referencia];
            h_frec = [h_frec(2:end), frec];
        end

        % Update plots
        set(lnVRef,  'XData', h_t, 'YData', h_vref);
        set(lnVReal, 'XData', h_t, 'YData', h_vr);
        set(lnVSens, 'XData', h_t, 'YData', h_vs);
        set(lnWRod,  'XData', h_t, 'YData', h_wrod);
        set(lnFreq,  'XData', h_t, 'YData', h_frec);

        xLo = max(0, t_sim - 5.0);
        xHi = max(5.0, t_sim);
        xlim(axCinta, [xLo, xHi]); ylim(axCinta, [0, 3.8]);
        xlim(axRod,   [xLo, xHi]); ylim(axRod,   [0, 8.0]);
        xlim(axPid,   [xLo, xHi]); ylim(axPid,   [0, 65]);

        % Update pulley & motor animation
        tformRod.Matrix = makehgtform('zrotate', rodillo.PosicionAngular);
        tformMot.Matrix = makehgtform('translate', [0, -1.8, 0]) * makehgtform('zrotate', motor.PosicionAngular);

        % Update telemetry text
        statusBox.String = eventLabel;
        telemetryBox.String = sprintf([ ...
            'LIVE TELEMETRY (240 Hz)\n' ...
            '-----------------------\n' ...
            'Time:       %6.2f s\n' ...
            'Ref Speed:  %6.2f m/s\n' ...
            'Belt Speed: %6.2f m/s\n' ...
            'Total Mass: %6.1f kg\n' ...
            'Motor Tq:   %6.2f N*m\n' ...
            'VFD Freq:   %6.1f Hz'], ...
            t_sim, control.Referencia, cinta.VelocidadCinta, ...
            cinta.MasaTotal, motor.TorqueMotor, frec);

        drawnow;
        writeVideo(vw, getframe(fig));
    end

    close(vw);
    close(fig);
    fprintf('Demo AVI recorded successfully: %s\n', outputAvi);
end
