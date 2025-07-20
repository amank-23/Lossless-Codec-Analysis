% main_CompressionSystem.m
% Main script to run and test the data compression system.

clear; clc; close all;

% --- Configuration ---
% Choose algorithm: 1 for Adaptive Huffman, 2 for Shannon-Fano
algorithm_choice = 2; 

% Input string for compression
input_string = 'aaaaabbbbbbbbcccccccccc';
% input_string = fileread('your_text_file.txt'); % Alternative: read from file

fprintf('--- Dynamic Data Compression System ---\n');
fprintf('Input String: "%s"\n', input_string);
fprintf('Original Length: %d characters\n', length(input_string));
original_bits = length(input_string) * 8;
fprintf('Original Size: %d bits\n\n', original_bits);


switch algorithm_choice
    case 1
        % --- Adaptive Huffman Coding ---
        fprintf('--- Running Adaptive Huffman Coding ---\n');
        
        % Encoding
        encoder = AdaptiveHuffmanEncoder();
        tic;
        huffman_encoded_bits = encoder.encode(input_string);
        huffman_encoding_time = toc;
        
        % Decoding
        decoder = AdaptiveHuffmanDecoder();
        tic;
        huffman_decoded_string = decoder.decode(huffman_encoded_bits);
        huffman_decoding_time = toc;
        
        % Results
        compressed_bits = length(huffman_encoded_bits);
        compression_ratio = original_bits / compressed_bits;
        
        fprintf('Encoding Time: %.6f seconds\n', huffman_encoding_time);
        fprintf('Decoding Time: %.6f seconds\n', huffman_decoding_time);
        fprintf('Compressed Size: %d bits\n', compressed_bits);
        fprintf('Compression Ratio: %.2f : 1\n', compression_ratio);
        fprintf('Decoded string matches original: %s\n', string(strcmp(input_string, huffman_decoded_string)));

    case 2
        % --- Shannon-Fano Coding ---
        fprintf('--- Running Shannon-Fano Coding ---\n');

        % Encoding
        tic;
        [sf_encoded_bits, sf_code_map] = ShannonFano.encode(input_string);
        sf_encoding_time = toc;
        
        % Decoding
        tic;
        sf_decoded_string = ShannonFano.decode(sf_encoded_bits, sf_code_map);
        sf_decoding_time = toc;

        % Results
        compressed_bits = length(sf_encoded_bits);
        % Note: For a fair comparison, the size of the code map should also be
        % considered part of the compressed data, but is omitted here for simplicity.
        compression_ratio = original_bits / compressed_bits;

        fprintf('Encoding Time: %.6f seconds\n', sf_encoding_time);
        fprintf('Decoding Time: %.6f seconds\n', sf_decoding_time);
        fprintf('Compressed Size: %d bits\n', compressed_bits);
        fprintf('Compression Ratio: %.2f : 1\n', compression_ratio);
        fprintf('Decoded string matches original: %s\n\n', string(strcmp(input_string, sf_decoded_string)));
        
        % Optional: Display the generated code map
        fprintf('Shannon-Fano Code Map:\n');
        keyset = keys(sf_code_map);
        for i = 1:length(keyset)
            key = keyset{i};
            fprintf("  '%s': %s\n", key, sf_code_map(key));
        end

    otherwise
        fprintf('Invalid algorithm choice. Please set algorithm_choice to 1 or 2.\n');
end