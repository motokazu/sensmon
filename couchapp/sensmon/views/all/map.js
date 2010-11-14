function(doc){
	if(doc.stime){
		emit(doc.stime, doc);
	}
}
