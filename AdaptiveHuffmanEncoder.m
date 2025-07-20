% AdaptiveHuffmanEncoder.m
% Implements the encoding logic for Adaptive Huffman.
% Optimized to preallocate node and output arrays for better performance.

classdef AdaptiveHuffmanEncoder < handle
    properties
        tree
        NYT_node
        nodes
        node_idx % Index for the preallocated nodes cell array
        seen_symbols
        output_bits = ''
        node_counter = 512
    end

    methods
        function obj = AdaptiveHuffmanEncoder()
            % Constructor initializes the tree identically to the decoder.
            obj.NYT_node = HuffmanNode([], 0, true, obj.node_counter);
            obj.tree = obj.NYT_node;
            % Preallocate for all possible ASCII symbols (256) and their internal nodes.
            obj.nodes = cell(1, 512);
            obj.nodes{1} = obj.NYT_node;
            obj.node_idx = 1;
            obj.seen_symbols = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function encoded_bits = encode(obj, input_str)
            % Preallocate output list.
            output_list = cell(1, length(input_str));
            output_idx = 0;
            
            for i = 1:length(input_str)
                input_char = input_str(i);
                if isKey(obj.seen_symbols, input_char)
                    node_to_update = obj.seen_symbols(input_char);
                    code = obj.get_code(node_to_update);
                    obj.update_tree(node_to_update);
                else 
                    code = obj.get_code(obj.NYT_node);
                    code = [code, dec2bin(double(input_char), 8)];
                    
                    % Create new nodes
                    obj.node_counter = obj.node_counter - 1;
                    new_internal_node = HuffmanNode([], 1, false, obj.node_counter);
                    obj.node_counter = obj.node_counter - 1;
                    new_leaf_node = HuffmanNode(input_char, 1, false, obj.node_counter);
                    
                    old_nyt_parent = obj.NYT_node.parent;
                    new_internal_node.parent = old_nyt_parent;
                    if ~isempty(old_nyt_parent)
                        old_nyt_parent.left = new_internal_node;
                    else
                        obj.tree = new_internal_node;
                    end
                    
                    new_internal_node.right = new_leaf_node;
                    new_internal_node.left = obj.NYT_node;
                    obj.NYT_node.parent = new_internal_node;
                    new_leaf_node.parent = new_internal_node;

                    % Add new nodes to preallocated cell array
                    obj.node_idx = obj.node_idx + 1;
                    obj.nodes{obj.node_idx} = new_internal_node;
                    obj.node_idx = obj.node_idx + 1;
                    obj.nodes{obj.node_idx} = new_leaf_node;

                    obj.seen_symbols(input_char) = new_leaf_node;
                    obj.update_tree(new_internal_node);
                end
                
                output_idx = output_idx + 1;
                output_list{output_idx} = code;
            end
            % Join only the populated part of the cell array
            encoded_bits = strjoin(output_list(1:output_idx), '');
        end

        function update_tree(obj, node)
            % Correctly implements the Vitter algorithm update rule.
            while ~isempty(node)
                block_leader = obj.find_block_leader(node);
                
                % A swap should occur if the node is not the leader of its block,
                % unless the leader is the node's parent.
                if ~isequal(node, block_leader) && ~isequal(node.parent, block_leader)
                    obj.swap_nodes(node, block_leader);
                end
                
                node.weight = node.weight + 1;
                node = node.parent;
            end
        end

        function leader = find_block_leader(obj, node)
            leader = node;
            target_weight = node.weight;
            target_id = node.node_id;
            % Iterate only over the valid nodes in the preallocated array
            for i = 1:obj.node_idx
                curr_node = obj.nodes{i};
                if ~isempty(curr_node) && curr_node.weight == target_weight && curr_node.node_id > target_id
                    leader = curr_node;
                    target_id = curr_node.node_id;
                end
            end
        end

        function swap_nodes(obj, node1, node2)
            % This robustly swaps any two nodes in the tree.
            parent1 = node1.parent;
            parent2 = node2.parent;

            if ~isempty(parent1)
                pos1_is_left = isequal(parent1.left, node1);
            end
            if ~isempty(parent2)
                pos2_is_left = isequal(parent2.left, node2);
            end

            node1.parent = parent2;
            node2.parent = parent1;

            if ~isempty(parent1)
                if pos1_is_left
                    parent1.left = node2;
                else
                    parent1.right = node2;
                end
            else
                obj.tree = node2;
            end

            if ~isempty(parent2)
                if pos2_is_left
                    parent2.left = node1;
                else
                    parent2.right = node1;
                end
            else
                obj.tree = node1;
            end
        end
        
        function code = get_code(~, node)
            % First pass: determine the depth to preallocate
            depth = 0;
            curr = node;
            while ~isempty(curr.parent)
                depth = depth + 1;
                curr = curr.parent;
            end

            if depth == 0
                code = '';
                return;
            end

            % Preallocate a character array for the path
            path = char(zeros(1, depth));
            
            % Second pass: fill the preallocated array from end to beginning
            idx = depth;
            curr = node;
            while ~isempty(curr.parent)
                p = curr.parent;
                if isequal(p.left, curr)
                    path(idx) = '0';
                else
                    path(idx) = '1';
                end
                curr = p;
                idx = idx - 1;
            end
            code = path; % Already a string, no join/fliplr needed
        end
    end
end
