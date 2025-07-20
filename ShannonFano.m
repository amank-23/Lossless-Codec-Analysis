% ShannonFano.m
% Contains static methods for Shannon-Fano encoding and decoding.
% Optimized to preallocate arrays and use StringBuilder for performance.

classdef ShannonFano
    methods (Static)
        function [encoded_bits, code_map] = encode(input_str)
            if isempty(input_str)
                encoded_bits = '';
                code_map = containers.Map();
                return;
            end
            
            symbols = unique(input_str);
            counts = zeros(1, length(symbols));
            for i = 1:length(symbols)
                counts(i) = sum(input_str == symbols(i));
            end
            
            probabilities = counts / length(input_str);
            
            [~, sort_idx] = sort(probabilities, 'descend');
            sorted_symbols = symbols(sort_idx);
            sorted_probs = probabilities(sort_idx);
            
            code_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
            % Update call to build_codes to handle the returned map, satisfying the linter.
            code_map = ShannonFano.build_codes(code_map, sorted_symbols, sorted_probs, '');
            
            output_list = cell(1, length(input_str));
            for i = 1:length(input_str)
                output_list{i} = code_map(input_str(i));
            end
            encoded_bits = strjoin(output_list, '');
        end

        % Updated function to return the modified map, making data flow explicit.
        function code_map = build_codes(code_map, symbols, probs, prefix)
            % Base case for recursion, optimized for performance and clarity.
            if isempty(symbols)
                return;
            end
            if isscalar(symbols)
                code_map(symbols) = prefix;
                return;
            end
            
            % Find split point. Initialize split_idx to a valid default.
            split_idx = length(symbols) - 1; 
            cumulative_prob = 0;
            total_prob = sum(probs);
            
            % Loop to find the optimal split point
            for i = 1:length(symbols)-1
                cumulative_prob = cumulative_prob + probs(i);
                if cumulative_prob >= total_prob / 2
                    split_idx = i;
                    break;
                end
            end
            
            % Recursive calls that now re-assign the returned map.
            code_map = ShannonFano.build_codes(code_map, symbols(1:split_idx), probs(1:split_idx), [prefix '0']);
            code_map = ShannonFano.build_codes(code_map, symbols(split_idx+1:end), probs(split_idx+1:end), [prefix '1']);
        end

        function decoded_str = decode(encoded_bits, code_map)
            if isempty(encoded_bits)
                decoded_str = '';
                return;
            end
            
            % Create a reverse map for efficient lookup
            reverse_map = containers.Map(values(code_map), keys(code_map));
            
            % Preallocate output_list for speed. Max possible length is length of bit_stream.
            output_list = cell(1, length(encoded_bits));
            output_idx = 0;
            
            % Use java.lang.StringBuilder for efficient string building in a loop
            sb = java.lang.StringBuilder();
            
            for i = 1:length(encoded_bits)
                sb.append(encoded_bits(i));
                current_code = char(sb.toString());
                if isKey(reverse_map, current_code)
                    output_idx = output_idx + 1;
                    output_list{output_idx} = reverse_map(current_code);
                    sb.setLength(0); % Reset for the next code
                end
            end
            
            % Join only the populated part of the cell array
            decoded_str = strjoin(output_list(1:output_idx), '');
        end
    end
end
