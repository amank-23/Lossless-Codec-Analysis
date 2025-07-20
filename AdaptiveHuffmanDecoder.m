% AdaptiveHuffmanDecoder.m
% Implements the decoding logic for Adaptive Huffman.
% Optimized to preallocate node and output arrays for better performance.

classdef AdaptiveHuffmanDecoder < handle
    properties
        tree
        NYT_node
        nodes
        node_idx % Index for the preallocated nodes cell array
        seen_symbols
        output_string = ''
        node_counter = 512
    end

    methods
        function obj = AdaptiveHuffmanDecoder()
            % Constructor initializes the tree identically to the encoder.
            obj.NYT_node = HuffmanNode([], 0, true, obj.node_counter);
            obj.tree = obj.NYT_node;
            % Preallocate for all possible ASCII symbols (256) and their internal nodes.
            obj.nodes = cell(1, 512);
            obj.nodes{1} = obj.NYT_node;
            obj.node_idx = 1;
            obj.seen_symbols = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function decoded_str = decode(obj, bit_stream)
            % Preallocate output list.
            output_list = cell(1, length(bit_stream));
            output_idx = 0;
            
            current_node = obj.tree;
            i = 1;
            node_to_update = [];

            while i <= length(bit_stream)
                if isequal(current_node, obj.NYT_node)
                    if i + 7 > length(bit_stream)
                        error('Incomplete bit stream for new symbol.');
                    end
                    char_bits = bit_stream(i:i+7);
                    decoded_char = char(bin2dec(char_bits));
                    i = i + 8;
                    
                    output_idx = output_idx + 1;
                    output_list{output_idx} = decoded_char;
                    
                    % Create new nodes (mirroring encoder)
                    obj.node_counter = obj.node_counter - 1;
                    new_internal_node = HuffmanNode([], 1, false, obj.node_counter);
                    obj.node_counter = obj.node_counter - 1;
                    new_leaf_node = HuffmanNode(decoded_char, 1, false, obj.node_counter);
                    
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

                    obj.node_idx = obj.node_idx + 1;
                    obj.nodes{obj.node_idx} = new_internal_node;
                    obj.node_idx = obj.node_idx + 1;
                    obj.nodes{obj.node_idx} = new_leaf_node;

                    obj.seen_symbols(decoded_char) = new_leaf_node;
                    node_to_update = new_internal_node;
                else 
                    % Traverse tree based on the current bit
                    if bit_stream(i) == '0'
                        current_node = current_node.left;
                    else
                        current_node = current_node.right;
                    end
                    i = i + 1;
                    
                    % If we landed on a leaf, it's a decoded symbol
                    if isempty(current_node.left)
                        if ~isequal(current_node, obj.NYT_node)
                            decoded_char = current_node.symbol;
                            output_idx = output_idx + 1;
                            output_list{output_idx} = decoded_char;
                            node_to_update = current_node;
                        end
                    end
                end
                
                % If a symbol was decoded (either new or existing), update the tree
                if ~isempty(node_to_update)
                    obj.update_tree(node_to_update);
                    current_node = obj.tree; % Reset to root for next symbol
                    node_to_update = []; % Reset update flag
                end
            end
            % Join only the populated part of the cell array
            decoded_str = strjoin(output_list(1:output_idx), '');
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
    end
end
