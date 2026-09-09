// Minimal, dependency-free matrix/vector math for the EKF. Deliberately
// small and simple (no external linear algebra package) — the state
// space here is only 8-dimensional, so a naive Gauss-Jordan inverse is
// more than fast enough, and keeping it dependency-free means the math
// is auditable by hand (see Document 2, Human-in-the-Loop Checkpoints).

class Matrix {
  Matrix(this.rows, this.cols, [List<double>? data])
      : data = data ?? List<double>.filled(rows * cols, 0.0);

  final int rows;
  final int cols;
  final List<double> data; // row-major

  double get(int r, int c) => data[r * cols + c];
  void set(int r, int c, double v) => data[r * cols + c] = v;

  static Matrix identity(int n) {
    final m = Matrix(n, n);
    for (var i = 0; i < n; i++) {
      m.set(i, i, 1.0);
    }
    return m;
  }

  static Matrix columnVector(List<double> values) {
    final m = Matrix(values.length, 1);
    for (var i = 0; i < values.length; i++) {
      m.set(i, 0, values[i]);
    }
    return m;
  }

  Matrix transpose() {
    final t = Matrix(cols, rows);
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        t.set(j, i, get(i, j));
      }
    }
    return t;
  }

  Matrix operator +(Matrix other) {
    assert(rows == other.rows && cols == other.cols);
    final m = Matrix(rows, cols);
    for (var i = 0; i < data.length; i++) {
      m.data[i] = data[i] + other.data[i];
    }
    return m;
  }

  Matrix operator -(Matrix other) {
    assert(rows == other.rows && cols == other.cols);
    final m = Matrix(rows, cols);
    for (var i = 0; i < data.length; i++) {
      m.data[i] = data[i] - other.data[i];
    }
    return m;
  }

  Matrix operator *(Matrix other) {
    assert(cols == other.rows);
    final m = Matrix(rows, other.cols);
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < other.cols; j++) {
        double sum = 0.0;
        for (var k = 0; k < cols; k++) {
          sum += get(i, k) * other.get(k, j);
        }
        m.set(i, j, sum);
      }
    }
    return m;
  }

  /// Gauss-Jordan inverse with partial pivoting. Throws on a singular
  /// matrix rather than silently returning garbage.
  Matrix inverse() {
    assert(rows == cols);
    final n = rows;
    final a = List<List<double>>.generate(
      n,
      (i) => List<double>.generate(n, (j) => get(i, j)),
    );
    final inv = List<List<double>>.generate(
      n,
      (i) => List<double>.generate(n, (j) => i == j ? 1.0 : 0.0),
    );

    for (var col = 0; col < n; col++) {
      var pivotRow = col;
      var maxVal = a[col][col].abs();
      for (var r = col + 1; r < n; r++) {
        if (a[r][col].abs() > maxVal) {
          maxVal = a[r][col].abs();
          pivotRow = r;
        }
      }
      if (maxVal < 1e-12) {
        throw StateError('Matrix is singular; cannot invert.');
      }
      if (pivotRow != col) {
        final tmpA = a[col];
        a[col] = a[pivotRow];
        a[pivotRow] = tmpA;
        final tmpI = inv[col];
        inv[col] = inv[pivotRow];
        inv[pivotRow] = tmpI;
      }

      final pivot = a[col][col];
      for (var j = 0; j < n; j++) {
        a[col][j] /= pivot;
        inv[col][j] /= pivot;
      }

      for (var r = 0; r < n; r++) {
        if (r == col) continue;
        final factor = a[r][col];
        if (factor == 0) continue;
        for (var j = 0; j < n; j++) {
          a[r][j] -= factor * a[col][j];
          inv[r][j] -= factor * inv[col][j];
        }
      }
    }

    final result = Matrix(n, n);
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        result.set(i, j, inv[i][j]);
      }
    }
    return result;
  }
}