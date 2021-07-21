/// Wrapper over Rust's slice type.
///
/// The main functionality comes from [rust_slice_to_c], a function
/// that convers Rust slices into Slice pointers.
///
/// The accompanying `impl_slice_destructor` macro, or the [free_slice]
/// function can be used to define destructors for a particular type.
#[repr(C)]
pub struct Slice<T> {
    ptr: *mut T,
    length: usize,
}

/// Exposes a Rust slice to FFI consumers as a [Slice].
pub fn rust_slice_to_c<T>(mut slice: Box<[T]>) -> *mut Slice<T> {
    Box::into_raw(Box::new(Slice {
        ptr: slice.as_mut_ptr(),
        length: slice.len(),
    }))
}

pub fn free_slice<T>(ptr: *mut Slice<T>) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let raw = Box::from_raw(ptr);
        std::slice::from_raw_parts_mut(raw.ptr.cast::<T>(), raw.length);
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
