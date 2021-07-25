use std::mem::forget;

/// Wrapper over Rust's slice type.
///
/// The main functionality comes from [rust_slice_to_c], a function
/// that converts Rust slices into Slice pointers.
///
/// The accompanying `impl_slice_destructor` macro, or the [free_slice]
/// function can be used to define destructors for a particular type.
///
/// It is highly unsafe to mutate this slice before it is returned to the Rust side.
#[repr(C)]
pub struct Slice<T> {
    length: usize,
    ptr: *mut T,
}

#[cfg(test)]
mod tests {

    use super::*;
    #[test]
    fn preserves_contents() {
        let squares: Box<[_]> = (0..9).into_iter().map(|e| e * e).collect();
        let clone = squares.clone();
        let slice = rust_slice_to_c(squares);
        let rebuilt = unsafe {
            let slice = Box::from_raw(slice);
            std::slice::from_raw_parts(slice.ptr, slice.length)
        };
        assert_eq!(&clone[..], rebuilt);
    }
}

/// Exposes a Rust slice to FFI consumers as a [Slice].
///
/// This function accepts a boxed slice, which can be obtained via
/// [Vec::into_boxed_slice](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.into_boxed_slice)
/// or [collect](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect)ing
/// an iterator into one, i.e. `.collect::<Box<_>>()`.
///
/// Ownership of the slice is handed off to the C side, and must be freed with [free_slice]
/// to avoid leaking memory.
pub fn rust_slice_to_c<T>(slice: Box<[T]>) -> *mut Slice<T> {
    let slice = Box::leak(slice);
    let ptr = slice.as_mut_ptr();
    let length = slice.len();
    forget(slice);
    Box::into_raw(Box::new(Slice { ptr, length }))
}

pub fn free_slice<T>(ptr: *mut Slice<T>) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let raw = Box::from_raw(ptr);
        std::slice::from_raw_parts_mut(raw.ptr, raw.length);
    }
}

#[macro_export]
macro_rules! impl_slice_destructor {
    ($Type:ty, $name:ident) => {
        #[no_mangle]
        pub extern "C" fn $name(ptr: *mut $crate::slice::Slice<$Type>) {
            $crate::slice::free_slice(ptr);
        }
    };
}
