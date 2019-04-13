/*
THIS FILE WAS AUTOGENERATED! DO NOT EDIT!
file to edit: 01a_fastai_layers.ipynb

*/
        

import TensorFlow

/// `Layer` with some experimental extra features.
///
/// This refines `Layer` so that it can be used with deep learning library utilities. If this becomes
/// too restrictive, we can remove the refinement and re-implement `Optimizer`.
public protocol FALayer: Layer {
    var delegate: LayerDelegate<Output> { get set }
    
    /// Returns the output obtained from applying the layer to the given input.
    ///
    /// - Parameters:
    ///   - input: The input to the layer.
    ///   - context: The contextual information for the layer application, e.g. the current learning
    ///     phase.
    /// - Returns: The output.
    @differentiable
    func forward(_ input: Input, in context: Context) -> Output
}

// TODO: This doesn't actually work. So we'll just paste it into every layer definition for now.
// /// Handles delegation when the layer is applied.
// extension FALayer {
//     @differentiable
//     public func applied(to input: Input, in context: Context) -> Output {
//         let activation = forward(input, in: context)
//         delegate.didProduceActivation(activation, in: context)
//         return activation
//     }
// }

open class LayerDelegate<Output> {
    public init() {}
    
    /// Called when a layer produces an activation.
    open func didProduceActivation(_ activation: Output, in context: Context) {}
}


/// A densely-connected neural network layer.
///
/// `Dense` implements the operation `activation(matmul(input, weight) + bias)`, where `weight` is
/// a weight matrix, `bias` is a bias vector, and `activation` is an element-wise activation
/// function.
@_fixed_layout
public struct FADense<Scalar: TensorFlowFloatingPoint>: FALayer {       
    /// The weight matrix.
    public var weight: Tensor<Scalar>
    /// The bias vector.
    public var bias: Tensor<Scalar>
    public typealias Activation = @differentiable (Tensor<Scalar>) -> Tensor<Scalar>
    /// The element-wise activation function.
    @noDerivative public let activation: Activation
    
    @noDerivative public var delegate: LayerDelegate<Output> = LayerDelegate()

    public init(
        weight: Tensor<Scalar>,
        bias: Tensor<Scalar>,
        activation: @escaping Activation
    ) {
        self.weight = weight
        self.bias = bias
        self.activation = activation
    }

    /// Returns the output obtained from applying the layer to the given input.
    ///
    /// - Parameters:
    ///   - input: The input to the layer.
    ///   - context: The contextual information for the layer application, e.g. the current learning
    ///     phase.
    /// - Returns: The output.
    @differentiable
    public func forward(_ input: Tensor<Scalar>, in _: Context) -> Tensor<Scalar> {
        return activation(matmul(input, weight) + bias)
    }
    
    @differentiable
    public func applied(to input: Tensor<Scalar>, in context: Context) -> Tensor<Scalar> {
        let activation = forward(input, in: context)
        delegate.didProduceActivation(activation, in: context)
        return activation
    }
}

public extension FADense {
    /// Creates a `Dense` layer with the specified input size, output size, and element-wise
    /// activation function. The weight matrix is created with shape `[inputSize, outputSize]` and
    /// is initialized using Glorot uniform initialization with the specified seed. The bias vector
    /// is created with shape `[outputSize]` and is initialized with zeros.
    ///
    /// - Parameters:
    ///   - inputSize: The dimensionality of the input space.
    ///   - outputSize: The dimensionality of the output space.
    ///   - activation: The activation function to use. The default value is `identity(_:)`.
    ///   - seed: The random seed for initialization. The default value is random.
    init(
        inputSize: Int,
        outputSize: Int,
        activation: @escaping Activation = identity,
        seed: (Int64, Int64) = (Int64.random(in: Int64.min..<Int64.max),
                                Int64.random(in: Int64.min..<Int64.max))
    ) {
        self.init(weight: Tensor(glorotUniform: [Int32(inputSize), Int32(outputSize)],
                                 seed: seed),
                  bias: Tensor(zeros: [Int32(outputSize)]),
                  activation: activation)
    }
}


/// A 2-D convolution layer (e.g. spatial convolution over images).
///
/// This layer creates a convolution filter that is convolved with the layer input to produce a
/// tensor of outputs.
@_fixed_layout
public struct FAConv2D<Scalar: TensorFlowFloatingPoint>: FALayer {
    /// The 4-D convolution kernel.
    public var filter: Tensor<Scalar>
    /// The bias vector.
    public var bias: Tensor<Scalar>
    /// An activation function.
    public typealias Activation = @differentiable (Tensor<Scalar>) -> Tensor<Scalar>
    /// The element-wise activation function.
    @noDerivative public let activation: Activation
    /// The strides of the sliding window for spatial dimensions.
    @noDerivative public let strides: (Int32, Int32)
    /// The padding algorithm for convolution.
    @noDerivative public let padding: Padding
    
    @noDerivative public var delegate: LayerDelegate<Output> = LayerDelegate()

    /// Creates a `Conv2D` layer with the specified filter, bias, activation function, strides, and
    /// padding.
    ///
    /// - Parameters:
    ///   - filter: The 4-D convolution kernel.
    ///   - bias: The bias vector.
    ///   - activation: The element-wise activation function.
    ///   - strides: The strides of the sliding window for spatial dimensions.
    ///   - padding: The padding algorithm for convolution.
    public init(
        filter: Tensor<Scalar>,
        bias: Tensor<Scalar>,
        activation: @escaping Activation,
        strides: (Int, Int),
        padding: Padding
    ) {
        self.filter = filter
        self.bias = bias
        self.activation = activation
        (self.strides.0, self.strides.1) = (Int32(strides.0), Int32(strides.1))
        self.padding = padding
    }

    /// Returns the output obtained from applying the layer to the given input.
    ///
    /// - Parameters:
    ///   - input: The input to the layer.
    ///   - context: The contextual information for the layer application, e.g. the current learning
    ///     phase.
    /// - Returns: The output.
    @differentiable
    public func forward(_ input: Tensor<Scalar>, in _: Context) -> Tensor<Scalar> {
        return activation(input.convolved2D(withFilter: filter,
                                            strides: (1, strides.0, strides.1, 1),
                                            padding: padding) + bias)
    }
    
    @differentiable
    public func applied(to input: Tensor<Scalar>, in context: Context) -> Tensor<Scalar> {
        let activation = forward(input, in: context)
        delegate.didProduceActivation(activation, in: context)
        return activation
    }
}

public extension FAConv2D {
    /// Creates a `Conv2D` layer with the specified filter shape, strides, padding, and
    /// element-wise activation function. The filter tensor is initialized using Glorot uniform
    /// initialization with the specified generator. The bias vector is initialized with zeros.
    ///
    /// - Parameters:
    ///   - filterShape: The shape of the 4-D convolution kernel.
    ///   - strides: The strides of the sliding window for spatial dimensions.
    ///   - padding: The padding algorithm for convolution.
    ///   - activation: The element-wise activation function.
    ///   - generator: The random number generator for initialization.
    ///
    /// - Note: Use `init(filterShape:strides:padding:activation:seed:)` for faster random
    ///   initialization.
    init<G: RandomNumberGenerator>(
        filterShape: (Int, Int, Int, Int),
        strides: (Int, Int) = (1, 1),
        padding: Padding = .valid,
        activation: @escaping Activation = identity,
        generator: inout G
    ) {
        let filterTensorShape = TensorShape([
            Int32(filterShape.0), Int32(filterShape.1),
            Int32(filterShape.2), Int32(filterShape.3)])
        self.init(
            filter: Tensor(glorotUniform: filterTensorShape, generator: &generator),
            bias: Tensor(zeros: TensorShape([Int32(filterShape.3)])),
            activation: activation,
            strides: strides,
            padding: padding)
    }
}

public extension FAConv2D {
    /// Creates a `Conv2D` layer with the specified filter shape, strides, padding, and
    /// element-wise activation function. The filter tensor is initialized using Glorot uniform
    /// initialization with the specified seed. The bias vector is initialized with zeros.
    ///
    /// - Parameters:
    ///   - filterShape: The shape of the 4-D convolution kernel.
    ///   - strides: The strides of the sliding window for spatial dimensions.
    ///   - padding: The padding algorithm for convolution.
    ///   - activation: The element-wise activation function.
    ///   - seed: The random seed for initialization. The default value is random.
    init(
        filterShape: (Int, Int, Int, Int),
        strides: (Int, Int) = (1, 1),
        padding: Padding = .valid,
        activation: @escaping Activation = identity,
        seed: (Int64, Int64) = (Int64.random(in: Int64.min..<Int64.max),
                                Int64.random(in: Int64.min..<Int64.max))
    ) {
        let filterTensorShape = TensorShape([
            Int32(filterShape.0), Int32(filterShape.1),
            Int32(filterShape.2), Int32(filterShape.3)])
        self.init(
            filter: Tensor(glorotUniform: filterTensorShape, seed: seed),
            bias: Tensor(zeros: TensorShape([Int32(filterShape.3)])),
            activation: activation,
            strides: (strides.0, strides.1),
            padding: padding)
    }
}


/// An average pooling layer for spatial data.
@_fixed_layout
public struct FAAvgPool2D<Scalar: TensorFlowFloatingPoint>: FALayer {
    /// The size of the sliding reduction window for pooling.
    @noDerivative let poolSize: (Int32, Int32, Int32, Int32)
    /// The strides of the sliding window for each dimension of a 4-D input.
    /// Strides in non-spatial dimensions must be `1`.
    @noDerivative let strides: (Int32, Int32, Int32, Int32)
    /// The padding algorithm for pooling.
    @noDerivative let padding: Padding
    
    @noDerivative public var delegate: LayerDelegate<Output> = LayerDelegate()

    /// Creates a average pooling layer.
    public init(
        poolSize: (Int, Int, Int, Int),
        strides: (Int, Int, Int, Int),
        padding: Padding
    ) {
        (self.poolSize.0, self.poolSize.1, self.poolSize.2, self.poolSize.3)
            = (Int32(poolSize.0), Int32(poolSize.1), Int32(poolSize.2), Int32(poolSize.3))
        (self.strides.0, self.strides.1, self.strides.2, self.strides.3)
            = (Int32(strides.0), Int32(strides.1), Int32(strides.2), Int32(strides.3))
        self.padding = padding
    }

    /// Creates a average pooling layer.
    ///
    /// - Parameters:
    ///   - poolSize: Vertical and horizontal factors by which to downscale.
    ///   - strides: The strides.
    ///   - padding: The padding.
    public init(poolSize: (Int, Int), strides: (Int, Int), padding: Padding = .valid) {
        self.poolSize = (1, Int32(poolSize.0), Int32(poolSize.1), 1)
        self.strides = (1, Int32(strides.0), Int32(strides.1), 1)
        self.padding = padding
    }

    /// Returns the output obtained from applying the layer to the given input.
    ///
    /// - Parameters:
    ///   - input: The input to the layer.
    ///   - context: The contextual information for the layer application, e.g. the current learning
    ///     phase.
    /// - Returns: The output.
    @differentiable
    public func forward(_ input: Tensor<Scalar>, in _: Context) -> Tensor<Scalar> {
        return input.averagePooled(kernelSize: poolSize, strides: strides, padding: padding)
    }
    
    @differentiable
    public func applied(to input: Tensor<Scalar>, in context: Context) -> Tensor<Scalar> {
        let activation = forward(input, in: context)
        delegate.didProduceActivation(activation, in: context)
        return activation
    }
}