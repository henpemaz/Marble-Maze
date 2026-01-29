extends Object
class_name AsyncResource

static func load(path: String, type_hint: String = "", use_sub_threads: bool = false, cache_mode: ResourceLoader.CacheMode = ResourceLoader.CacheMode.CACHE_MODE_REUSE)->Resource:
	var request:Error = ResourceLoader.load_threaded_request(path, type_hint, use_sub_threads, cache_mode)
	if request != Error.OK:
		printerr(error_string(request))
		return null
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await Engine.get_main_loop().process_frame
	return ResourceLoader.load_threaded_get(path)
