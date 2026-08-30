"""
Golden Reference Model for 4x4 INT8 Matrix Multiplication AI Accelerator
with Optional INT32 ReLU Activation.

This script implements:
1. Exact signed INT8 matrix multiplication (C = A @ B) with signed INT32 accumulation.
2. Optional ReLU activation: C = max(0, C).
3. Synthetic and random test vector generation.
4. Verification against reference NumPy operations.
"""

import numpy as np

def relu(matrix: np.ndarray) -> np.ndarray:
    """Apply Rectified Linear Unit activation element-wise."""
    return np.maximum(matrix, 0)

def matmul_golden(a: np.ndarray, b: np.ndarray, apply_relu: bool = False) -> np.ndarray:
    """
    Perform 4x4 matrix multiplication matching the hardware accelerator:
    - Input A: Signed INT8
    - Input B: Signed INT8
    - Accumulation: Signed INT32
    - Optional ReLU activation
    """
    # Ensure inputs are signed int8
    a_int8 = np.asarray(a, dtype=np.int8)
    b_int8 = np.asarray(b, dtype=np.int8)
    
    # Cast to int32 before multiplication to prevent overflow, matching hardware MAC
    a_int32 = a_int8.astype(np.int32)
    b_int32 = b_int8.astype(np.int32)
    
    # Compute dot products
    c_int32 = np.matmul(a_int32, b_int32)
    
    if apply_relu:
        c_int32 = relu(c_int32)
        
    return c_int32

def generate_random_test(min_val: int = -20, max_val: int = 20, seed: int = None):
    """Generate random INT8 4x4 matrices and compute expected result."""
    if seed is not None:
        np.random.seed(seed)
    a = np.random.randint(min_val, max_val, size=(4, 4), dtype=np.int8)
    b = np.random.randint(min_val, max_val, size=(4, 4), dtype=np.int8)
    return a, b

def print_matrix(name: str, mat: np.ndarray):
    """Pretty-print a 4x4 matrix."""
    print(f"{name}:")
    for row in mat:
        print("  [" + ", ".join(f"{val:6d}" for val in row) + "]")

def run_tests():
    print("=" * 60)
    print("       AI ACCELERATOR PYTHON GOLDEN REFERENCE MODEL       ")
    print("=" * 60)

    # Test 1: Specified standard matrix
    a1 = np.array([
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [1, 2, 1, 2],
        [3, 4, 3, 4]
    ], dtype=np.int8)

    b1 = np.array([
        [1, 0, 2, 1],
        [0, 1, 1, 2],
        [2, 1, 0, 1],
        [1, 2, 1, 0]
    ], dtype=np.int8)

    c1_linear = matmul_golden(a1, b1, apply_relu=False)
    print("\n--- TEST 1: Standard Matrix Multiplication (Linear) ---")
    print_matrix("Matrix A", a1)
    print_matrix("Matrix B", b1)
    print_matrix("Expected Matrix C", c1_linear)

    # Test 2: Negative signed values with ReLU
    a2 = np.array([
        [-2,  3, -1,  4],
        [ 1, -5,  2, -3],
        [-4,  1, -2,  0],
        [ 3, -2,  1, -1]
    ], dtype=np.int8)

    b2 = np.array([
        [ 2, -1,  3, -2],
        [-3,  2, -1,  4],
        [ 1, -4,  2, -1],
        [-2,  1, -3,  2]
    ], dtype=np.int8)

    c2_linear = matmul_golden(a2, b2, apply_relu=False)
    c2_relu = matmul_golden(a2, b2, apply_relu=True)
    print("\n--- TEST 2: Negative Matrix with ReLU ---")
    print_matrix("Matrix A", a2)
    print_matrix("Matrix B", b2)
    print_matrix("Raw C (Before ReLU)", c2_linear)
    print_matrix("Expected Matrix C (After ReLU)", c2_relu)

    # Test 3: Random Tests
    print("\n--- TEST 3: Random INT8 Matrices with ReLU ---")
    a3, b3 = generate_random_test(seed=42)
    c3_relu = matmul_golden(a3, b3, apply_relu=True)
    print_matrix("Matrix A", a3)
    print_matrix("Matrix B", b3)
    print_matrix("Expected Matrix C (ReLU)", c3_relu)

    print("\n" + "=" * 60)
    print("Python Golden Model Execution Complete.")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
