# Mechatronic Conveyor Belt PID Simulation (MATLAB)

Object-oriented real-time electromechanical simulation and closed-loop PID speed control of an industrial conveyor belt driven by a Variable Frequency Drive (VFD), electric motor, and reduction gearbox, built in **MATLAB** with an interactive `uifigure` control panel and live pulley/motor animation (`hgtransform`).

---

## System Architecture

```text
               +-----------+     +-----+     +-------+     +------------------+     +---------------+
v_ref (m/s) -> |  PID +    | ->  | VFD | ->  | Motor | ->  | Gearbox & Roller | ->  | Conveyor Belt | -> v_real (m/s)
     (-)  ^    | Anti-Wind |  f  | 1st | e_a | (EDO) | w_m | (i = 5, R_eff)   | w_r | (Coulomb F_r) |         |
          |    +-----------+     +-----+     +-------+     +------------------+     +---------------+         |
          |                                                                                                   |
          +----------------------------------[ Velocity Sensor (1st-order lag + bias + noise) ]<--------------+
```

### Repository Structure

```text
mechatronic-conveyor-simulation/
├── run_app.m                                              # Entry point (adds src/ to path and launches GUI)
├── src/
│   ├── AppRodillos.m                                      # Interactive MATLAB uifigure GUI (240 Hz physics / 24 fps render)
│   ├── Inicializar.m                                      # Default electromechanical and PID parameters
│   ├── Control.m                                          # Discrete PID controller with saturation & conditional anti-windup
│   ├── VFD.m                                              # First-order VFD dynamics translating frequency (Hz) to voltage
│   ├── Motor.m                                            # Armature electrical & rotor mechanical ODEs
│   ├── Rodillo.m                                          # Gearbox (ratio i) and drive roller reflected inertia/torque
│   ├── Cinta.m                                            # Belt linear kinematics, dynamic load mass, static/dynamic friction
│   ├── Sensor.m                                           # First-order velocity sensor with additive bias and Gaussian noise
│   └── IntegracionEuler.m                                 # Explicit Euler integration step
└── docs/
    └── MemoriaModelado_Arquitectura_DanielJimenezSoler.pdf # Full modeling & architecture report (Spanish)
```

---

## Mathematical Model

### 1. Motor & VFD Actuator
The VFD is modeled as a first-order lag with time constant $\tau_{\text{VFD}}$ scaling commanded frequency $f$ into equivalent armature voltage $e_a$ via a steady-state $V/f$ gain $k$:

$$\frac{de_a}{dt} = \frac{1}{\tau_{\text{VFD}}}\left(k\,f - e_a\right), \qquad k = \frac{4\pi}{P}\left(\frac{R_a B_m}{K_1} + K_b\right)$$

The motor electrical and rotational dynamics follow an equivalent DC armature model:

$$L_a \frac{di_a}{dt} = e_a - R_a i_a - K_b \omega_m, \qquad J_t \frac{d\omega_m}{dt} = K_1 i_a - B_m \omega_m - T_l$$

> **Modeling assumption:** Coupling a DC armature model with a pole-count $V/f$ steady-state law is a standard lumped-parameter simplification used to study closed-loop electromechanical load disturbances without full $d$-$q$ induction machine modeling.

### 2. Gearbox, Roller & Conveyor Belt
With gearbox ratio $i = 5$ and effective roller radius $R_{\text{eff}} = R_{\text{roller}} + \frac{e_{\text{belt}}}{2}$:

$$\omega_r = \frac{\omega_m}{i}, \qquad v_{\text{belt}} = \omega_r R_{\text{eff}}$$

$$J_t = J_m + \frac{m_{\text{total}} R_{\text{eff}}^2}{i^2}, \qquad T_l = \frac{F_{\text{friction}} R_{\text{eff}}}{i}$$

Belt friction switches between static Coulomb friction ($\mu_s = 0.5$) below breakaway and kinetic friction ($\mu_d = 0.4$) in motion, dynamically responding as boxes are added or removed in real time.

### 3. Sensor & Closed-Loop PID
- **Sensor**: First-order low-pass filter ($\tau_s = 0.05\text{ s}$) integrated independently of additive bias ($0.002\text{ m/s}$) and Gaussian noise ($\sigma = 10^{-4}\text{ m/s}$).
- **PID Controller**: Discrete PID ($K_p = 20$, $K_i = 50$, $K_d = 3$) saturated to $[0, 60]\text{ Hz}$ with conditional integrator clamping (anti-windup).

---

## Running the Simulation

Requirements: **MATLAB R2021a or newer** (uses `uifigure`, `uiknob`, `hgtransform`, and `timer`).

```matlab
% From the repository root in MATLAB:
run_app
```

From the interactive dashboard you can:
1. Start/stop the real-time physics loop (`START SIMULACION`) and toggle the motor (`START MOTOR`).
2. Change the target linear belt velocity (`0–5 m/s`) via the discrete knob.
3. Dynamically **add or remove boxes** of arbitrary weight (kg) to test load-disturbance rejection and motor stall behavior.
4. Inspect live plots of roller angular velocity $\omega_r$, linear belt velocity (reference vs. real vs. sensor), PID frequency command, and synchronized pulley/motor rotation.

---

## Author

**Daniel Jiménez Soler** · [GitHub](https://github.com/Daniijs) · [LinkedIn](https://www.linkedin.com/in/daniel-jimenez-soler/)
