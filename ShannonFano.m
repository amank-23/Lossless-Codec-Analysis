% ShannonFano.m
% Enhanced static Shannon-Fano encoder/decoder with overhead and padding support.

classdef ShannonFano
    methods (Static)
        function [encoded_bits, code_map, analysis] = encode(input_str)
            if isempty(input_str)
                encoded_bits = '';
                code_map = containers.Map();
                analysis = struct('compressed_size_ideal', 0, ...
                                  'compressed_size_realistic', 0, ...
                                  'overhead_bits', 0, ...
                                  'padded_bits', 0);
                return;
            end
            
            % Step 1: Count symbol frequencies
            symbols = unique(input_str);
            counts = zeros(1, length(symbols));
            for i = 1:length(symbols)
                counts(i) = sum(input_str == symbols(i));
            end
            probabilities = counts / length(input_str);

            % Step 2: Sort by descending probability
            [~, sort_idx] = sort(probabilities, 'descend');
            sorted_symbols = symbols(sort_idx);
            sorted_probs = probabilities(sort_idx);

            % Step 3: Build code map
            code_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
            code_map = ShannonFano.build_codes(code_map, sorted_symbols, sorted_probs, '');

            % Step 4: Encode bitstream
            output_list = cell(1, length(input_str));
            for i = 1:length(input_str)
                output_list{i} = code_map(input_str(i));
            end
            encoded_bits = strjoin(output_list, '');

            % Step 5: Overhead + Padding Simulation
            % a) Ideal: Just bitstream length
            compressed_size_ideal = length(encoded_bits);

            % b) Overhead: 8 bits per symbol + length of binary code string
            overhead_bits = 0;
            keyset = keys(code_map);
            for i = 1:length(keyset)
                sym = keyset{i};
                code = code_map(sym);
                overhead_bits = overhead_bits + 8 + length(code);
            end

            % c) Padding to full bytes
            padded_bits = ceil(compressed_size_ideal / 8) * 8;

            % d) Total realistic compressed size
            compressed_size_realistic = padded_bits + overhead_bits;

            % Output all sizes
            analysis = struct();
            analysis.compressed_size_ideal     = compressed_size_ideal;
            analysis.overhead_bits             = overhead_bits;
            analysis.padded_bits               = padded_bits;
            analysis.compressed_size_realistic = compressed_size_realistic;
        end

        function code_map = build_codes(code_map, symbols, probs, prefix)
            if isempty(symbols)
                return;
            end
            if isscalar(symbols)
                code_map(symbols) = prefix;
                return;
            end

            total_prob = sum(probs);
            split_idx = length(symbols) - 1;
            cumulative_prob = 0;

            for i = 1:length(symbols)-1
                cumulative_prob = cumulative_prob + probs(i);
                if cumulative_prob >= total_prob / 2
                    split_idx = i;
                    break;
                end
            end

            code_map = ShannonFano.build_codes(code_map, symbols(1:split_idx), probs(1:split_idx), [prefix '0']);
            code_map = ShannonFano.build_codes(code_map, symbols(split_idx+1:end), probs(split_idx+1:end), [prefix '1']);
        end

        function decoded_str = decode(encoded_bits, code_map)
            if isempty(encoded_bits)
                decoded_str = '';
                return;
            end

            reverse_map = containers.Map(values(code_map), keys(code_map));
            output_list = cell(1, length(encoded_bits));
            output_idx = 0;
            sb = java.lang.StringBuilder();

            for i = 1:length(encoded_bits)
                sb.append(encoded_bits(i));
                current_code = char(sb.toString());
                if isKey(reverse_map, current_code)
                    output_idx = output_idx + 1;
                    output_list{output_idx} = reverse_map(current_code);
                    sb.setLength(0);
                end
            end

            decoded_str = strjoin(output_list(1:output_idx), '');
        end
    end
end
