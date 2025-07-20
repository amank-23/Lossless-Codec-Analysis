% main_CompressionSystem.m
% Enhanced to loop through multiple test cases and generate comparative plots.
clear; clc; close all;

% --- Configuration ---
% Define multiple test cases (short strings to prevent errors)
test_cases = {
    'High Repetition', 'aaaaaaaaaaaaabbbbbbcccccccc';
    'Pattern Repetition', 'abcabcabcabcabcabcabcabcabc';
    'Mixed English', 'this_is_a_simple_test_string';
    'Few Symbols', '1111122222333334444455555';
    'No Repetition', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
};

% Initialize a structure to store results for plotting
num_tests = size(test_cases, 1);
results = struct(...
    'test_name', cell(1, num_tests), ...
    'huffman_ratio', zeros(1, num_tests), ...
    'sf_ratio', zeros(1, num_tests), ...
    'huffman_enc_time', zeros(1, num_tests), ...
    'sf_enc_time', zeros(1, num_tests), ...
    'huffman_dec_time', zeros(1, num_tests), ...
    'sf_dec_time', zeros(1, num_tests) ...
);

fprintf('--- Dynamic Data Compression System ---\n');
fprintf('--- Running Batch Analysis ---\n\n');

% --- Main Loop for Automated Testing ---
for i = 1:num_tests
    test_name = test_cases{i, 1};
    input_string = test_cases{i, 2};
    results(i).test_name = test_name;

    fprintf('==============================================\n');
    fprintf('Test Case %d: "%s"\n', i, test_name);
    fprintf('Input String: "%s"\n', input_string);
    original_bits = length(input_string) * 8;
    fprintf('Original Size: %d bits\n', original_bits);
    fprintf('==============================================\n\n');

    % --- 1. Adaptive Huffman Coding ---
    fprintf('--- Running Adaptive Huffman Coding ---\n');
    encoder = AdaptiveHuffmanEncoder();
    tic;
    huffman_encoded_bits = encoder.encode(input_string);
    huffman_encoding_time = toc;
    
    decoder = AdaptiveHuffmanDecoder();
    tic;
    huffman_decoded_string = decoder.decode(huffman_encoded_bits);
    huffman_decoding_time = toc;
    
    compressed_bits_huffman = length(huffman_encoded_bits);
    compression_ratio_huffman = original_bits / compressed_bits_huffman;
    
    fprintf('Encoding Time: %.6f seconds\n', huffman_encoding_time);
    fprintf('Decoding Time: %.6f seconds\n', huffman_decoding_time);
    fprintf('Compressed Size: %d bits\n', compressed_bits_huffman);
    fprintf('Compression Ratio: %.2f : 1\n', compression_ratio_huffman);
    fprintf('Decoded string matches original: %s\n\n', string(strcmp(input_string, huffman_decoded_string)));
    
    % Store results
    results(i).huffman_ratio = compression_ratio_huffman;
    results(i).huffman_enc_time = huffman_encoding_time;
    results(i).huffman_dec_time = huffman_decoding_time;

    % --- 2. Shannon-Fano Coding ---
    fprintf('--- Running Shannon-Fano Coding ---\n');
    tic;
    [sf_encoded_bits, sf_code_map, sf_analysis] = ShannonFano.encode(input_string);
    sf_encoding_time = toc;
    
    tic;
    sf_decoded_string = ShannonFano.decode(sf_encoded_bits, sf_code_map);
    sf_decoding_time = toc;
    
    compressed_bits_sf = sf_analysis.compressed_size_realistic;
    compression_ratio_sf = original_bits / compressed_bits_sf;
    
    fprintf('Encoding Time: %.6f seconds\n', sf_encoding_time);
    fprintf('Decoding Time: %.6f seconds\n', sf_decoding_time);
    fprintf('Compressed Size: %d bits (codebook + padding)\n', compressed_bits_sf);
    fprintf('Compression Ratio: %.2f : 1\n', compression_ratio_sf);
    fprintf('Decoded string matches original: %s\n\n', string(strcmp(input_string, sf_decoded_string)));
    
    % Store results
    results(i).sf_ratio = compression_ratio_sf;
    results(i).sf_enc_time = sf_encoding_time;
    results(i).sf_dec_time = sf_decoding_time;
end

% Close any figures generated within the Shannon-Fano class during the loop
close all;

% --- Graphical Analysis ---
fprintf('--- Generating Comparative Analysis Plots ---\n');

% Prepare data for plotting
test_names_cat = categorical({results.test_name});
% Reorder categories to match the initial definition
test_names_cat = reordercats(test_names_cat, test_cases(:,1)');

% Plot 1: Compression Ratio Comparison
figure('Name', 'Compression Ratio Comparison', 'NumberTitle', 'off');
bar_data_ratio = [results.huffman_ratio; results.sf_ratio]';
bar(test_names_cat, bar_data_ratio);
title('Algorithm Comparison: Compression Ratio');
ylabel('Compression Ratio (Original Size / Compressed Size)');
xlabel('Test Case');
legend('Adaptive Huffman', 'Shannon-Fano', 'Location', 'northwest');
grid on;

% Plot 2: Encoding Time Comparison
figure('Name', 'Encoding Time Comparison', 'NumberTitle', 'off');
bar_data_enc_time = [results.huffman_enc_time; results.sf_enc_time]' * 1000; % ms
bar(test_names_cat, bar_data_enc_time);
title('Algorithm Comparison: Encoding Time');
ylabel('Time (milliseconds)');
xlabel('Test Case');
legend('Adaptive Huffman', 'Shannon-Fano', 'Location', 'northwest');
grid on;

% Plot 3: Decoding Time Comparison
figure('Name', 'Decoding Time Comparison', 'NumberTitle', 'off');
bar_data_dec_time = [results.huffman_dec_time; results.sf_dec_time]' * 1000; % ms
bar(test_names_cat, bar_data_dec_time);
title('Algorithm Comparison: Decoding Time');
ylabel('Time (milliseconds)');
xlabel('Test Case');
legend('Adaptive Huffman', 'Shannon-Fano', 'Location', 'northwest');
grid on;

fprintf('Analysis complete. Displaying plots.\n');