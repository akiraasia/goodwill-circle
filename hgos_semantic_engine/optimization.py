import torch
import logging
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)

def quantize_model(model: SentenceTransformer) -> torch.nn.Module:
    """
    Applies dynamic quantization to the PyTorch model, converting
    float32 Linear layers to qint8. This dramatically reduces model 
    size and increases inference speed on CPUs without significant accuracy loss.
    """
    logger.info("Applying dynamic quantization to Linear layers...")
    # Dynamic quantization for the underlying Transformer
    quantized_model = torch.quantization.quantize_dynamic(
        model, 
        {torch.nn.Linear}, 
        dtype=torch.qint8
    )
    logger.info("Quantization complete.")
    return quantized_model

def export_to_torchscript(model: SentenceTransformer, example_text: str = "I want to become a doctor", output_path: str = "model.pt"):
    """
    Exports the model to TorchScript for production inference without Python overhead.
    Note: SentenceTransformers wraps a pipeline; tracing usually targets the base Transformer.
    """
    logger.info(f"Exporting model to TorchScript at {output_path}...")
    
    # Tokenize the example text
    features = model.tokenize([example_text])
    
    # Convert tokenized inputs to tensors
    input_ids = features['input_ids']
    attention_mask = features['attention_mask']
    
    # Trace the underlying HuggingFace auto_model (which is inside the first module of ST)
    base_model = model[0].auto_model
    base_model.eval()
    
    with torch.no_grad():
        traced_model = torch.jit.trace(base_model, (input_ids, attention_mask), strict=False)
        
    traced_model.save(output_path)
    logger.info("TorchScript export successful.")
    return traced_model

def export_to_onnx(model: SentenceTransformer, output_path: str = "model.onnx"):
    """
    Exports the base HuggingFace model to ONNX format.
    """
    logger.info(f"Exporting model to ONNX at {output_path}...")
    features = model.tokenize(["Test string"])
    input_ids = features['input_ids']
    attention_mask = features['attention_mask']
    
    base_model = model[0].auto_model
    base_model.eval()
    
    torch.onnx.export(
        base_model,
        (input_ids, attention_mask),
        output_path,
        input_names=['input_ids', 'attention_mask'],
        output_names=['last_hidden_state'],
        dynamic_axes={
            'input_ids': {0: 'batch_size', 1: 'sequence_length'},
            'attention_mask': {0: 'batch_size', 1: 'sequence_length'},
            'last_hidden_state': {0: 'batch_size', 1: 'sequence_length'}
        },
        opset_version=14
    )
    logger.info("ONNX export successful.")
