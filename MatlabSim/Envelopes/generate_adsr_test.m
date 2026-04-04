% Synthesizer Parameters
fs = 48000;         % CD-quality sample rate
A = 0.1;            % 100ms Attack
D = 0.2;            % 200ms Decay
S = 0.5;            % 50% Sustain volume
R = 0.4;            % 400ms Release
gate_time = 1.0;    % Note held for 1 second

% Generate the envelope
my_envelope = generate_adsr(A, D, S, R, gate_time, fs);

% Create a time vector for the X-axis so the plot is in seconds, not samples
t = (0:length(my_envelope)-1) / fs;

% Plot it!
plot(t, my_envelope, 'LineWidth', 2);
title('Digital ADSR Envelope');
xlabel('Time (seconds)');
ylabel('Amplitude (0.0 to 1.0)');
grid on;
ylim([0 1.1]);