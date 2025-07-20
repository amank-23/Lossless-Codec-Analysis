% HuffmanNode.m
% Defines the structure for a node in the Huffman tree. It's a handle class
% so that node properties (like children, parent) can be modified by
% reference, allowing the tree to be built and updated dynamically.

classdef HuffmanNode < handle
    properties
        symbol      % The character symbol
        weight      % Frequency of the symbol
        is_nyt      % Boolean flag for 'Not Yet Transmitted' node
        node_id     % Unique identifier for the node
        left        % Handle to the left child node
        right       % Handle to the right child node
        parent      % Handle to the parent node
    end

    methods
        function obj = HuffmanNode(symbol, weight, is_nyt, node_id)
            % Constructor to initialize a HuffmanNode object.
            if nargin > 0
                obj.symbol = symbol;
                obj.weight = weight;
                obj.is_nyt = is_nyt;
                obj.node_id = node_id;
                obj.left = [];
                obj.right = [];
                obj.parent = [];
            end
        end
    end
end
