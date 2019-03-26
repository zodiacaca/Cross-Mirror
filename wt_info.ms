
clearListener()

-- // no z value less than 0
-- // zero wiehgts removed
-- // absolutely symmetry

-- clear display
unregisterRedrawViewsCallback GW_display
GW_display = undefined

select_dialog_rf = undefined
select_dialog_ro = undefined

mirror_wtReserve_bones = #()
mirror_wtCross_bones = #()


rollout wtAssign_ro "" width:250 height:330
(
	-- structs
	struct wt
	(
		i,
		n,
		w
	)
	
	struct vtx
	(
		i,
		p
	)
	
	struct pair
	(
		l,
		r
	)
	
	-- variables
	local verts_count = 0
	local verts_l = #()
	local verts_r = #()
	local bone_indexes = #()
	local bone_pairs = #()
	local vert_pairs = #()
	local weights = #()
	
	local getBoneIndexes
	local getPairs
	local saveData
	local getWeights
	local getWeightSum
	local selectVertexes
	
	local skin = undefined
	
	local p_x = 5
	local p_y = 10
	
	
	/* --------------------
		Get Pairs
	-------------------- */
	GroupBox grp_pair "Generate Basic Data" \
	pos:[p_x,p_y] width:220 height:60
	
	-- get button
	button btn_pair "Get Pairs" \
	pos:[p_x+10,p_y+20] width:100 height:30
	on btn_pair pressed  do
	(
		if vert_pairs.count == 0 then
		(
			-- grid partition
			verts = #()
			for i = 1 to verts_count do
			(
				append verts (getVert $ i).z
			)
			z_max = amax verts
			verts = #()
			for i = 1 to verts_count do
			(
				append verts (getVert $ i).x
			)
			x_max = amax verts
			
			devide = 10
			z_seg = z_max*1.05/devide
			x_seg = x_max*1.05/devide*2
			
			for i = 1 to devide/2 do
			(
				for ii = 1 to devide do
				(
					verts_l[(i-1)*10+ii] = #()
				)
			)
			for i = 1 to devide/2 do
			(
				for ii = 1 to devide do
				(
					verts_r[(i-1)*10+ii] = #()
				)	
			)
			
			mid = 0.05
			progressStart "Finding grid..."
			for v = 1 to verts_count do
			(
				progressUpdate (100.0 * v / verts_count)
				if (getVert $ v).x > mid then
				(
					located = false
					i = 0 as integer
					ii = 0 as integer
					while not located do
					(
						if (getVert $ v).x > x_seg * i and (getVert $ v).x <= x_seg * (i+1) and \
						(getVert $ v).z > z_seg * ii and (getVert $ v).z <= z_seg * (ii+1) then
						(
							vert = vtx()
							vert.i = v
							vert.p = getVert $ v
							append verts_l[i*10+(ii+1)] vert
							
							located = true
						)
						else
						(
							ii += 1
							if ii == 10 then
							(
								i += 1
								ii = 0
							)
						)
					)
				)
				else if (getVert $ v).x < -mid then
				(
					located = false
					i = 0 as integer
					ii = 0 as integer
					while not located do
					(
						if (getVert $ v).x < -x_seg * i and (getVert $ v).x >= -x_seg * (i+1) and \
						(getVert $ v).z > z_seg * ii and (getVert $ v).z <= z_seg * (ii+1) then
						(
							vert = vtx()
							vert.i = v
							vert.p = getVert $ v
							append verts_r[i*10+(ii+1)] vert
							
							located = true
						)
						else
						(
							ii += 1
							if ii == 10 then
							(
								i += 1
								ii = 0
							)
						)
					)
				)
			)
			progressEnd()
			
			-- print single grid vertex count
			for i = 1 to 50 do
			(
				format "Vertex count(l): %\n" verts_l[i].count
			)
			for i = 1 to 50 do
			(
				format "Vertex count(r): %\n" verts_r[i].count
			)
		)
		
		-- get pairs
		if skin != undefined then
		(
			getBoneIndexes skin
			getPairs skin
		)
		
		-- save
		saveData()
	)
	
	
	/* --------------------
		Load
	-------------------- */
	GroupBox grp_load "Load Data" \
	pos:[p_x,p_y+70] width:220 height:60
	
	-- load button
	button btn_load "Load" \
	pos:[p_x+10,p_y+70+20] width:100 height:30
	on btn_load pressed  do
	(
		f_path = (getDir #scripts) + "\\temp_pairs.txt"
		if f_path != undefined then
		(
			vert_pairs = #()
			file = openFile f_path
			while eof file == false do
			(
				str = readLine file
				str = str as stringstream
				vtx_l = (readToken str) as integer
				skipSpace str
				vtx_r = (readToken str) as integer
				p = pair()
				vert = vtx()
				vert.i = vtx_l
				vert.p = getVert $ vtx_l
				p.l = vert
				vert = vtx()
				vert.i = vtx_r
				vert.p = getVert $ vtx_r
				p.r = vert
				appendifunique vert_pairs p
			)
			
			selectVertexes()
		)
	)
	
	
	/* --------------------
		Operate
	-------------------- */
	GroupBox grp_op "Operate" \
	pos:[p_x,p_y+70*2] width:220 height:140
	
	-- dispaly button
	radioButtons rdo_display "Display" \
	pos:[p_x+10,p_y+70*2+20] width:100 height:30 \
	labels:#("None", "Line", "Markers", "Both")
	on rdo_display changed state do
	(
		if state == 2 or state == 3 or state == 4 then
		(
			registerRedrawViewsCallback GW_display
		)
		else
		(
			unregisterRedrawViewsCallback GW_display
		)
	)
	
	-- cross button
	button btn_get_cross "Get Cross Weighted Bones" \
	pos:[p_x+10,p_y+70*2+60] width:160 height:30
	on btn_get_cross pressed  do
	(
		if select_dialog_rf != undefined do closeRolloutFloater select_dialog_rf
		select_dialog_rf = newRolloutFloater "" 400 320 200 200
		addRollout select_dialog_ro	select_dialog_rf
	)
	
	-- operate button
	button btn_operate "Operate" \
	pos:[p_x+10,p_y+70*2+100] width:100 height:30
	enabled:false
	on btn_operate pressed  do
	(
		struct bone_id_wt
		(
			i,
			w
		)
		
		check_verts = #()
		if skin != undefined then
		(
			for i = 1 to verts_count do
			(
				skinOps.unNormalizeVertex skin i true
			)
			
			vtx_r = #()	-- separate into single arrays
			vtx_l = #()
			for i = 1 to vert_pairs.count do
			(
				append vtx_r vert_pairs[i].r.i
				append vtx_l vert_pairs[i].l.i
			)
			
			bone_r = #()
			bone_l = #()
			for i = 1 to bone_pairs.count do
			(
				append bone_r bone_pairs[i].r
				append bone_l bone_pairs[i].l
			)
			
			cross_bone_r = #()
			cross_bone_l = #()
			for i = 1 to mirror_wtCross_bones.count do
			(
				append cross_bone_r mirror_wtCross_bones[i].r
				append cross_bone_l mirror_wtCross_bones[i].l
			)
			
			vert_reserve = #()		-- reserve bone corresponding with vertex
			reserve_bone = #()		-- position holder
			v_b_dist = #()		-- vertex to bone distances
			for i = 1 to mirror_wtReserve_bones.count do
			(
				b = getnodebyname (skinOps.GetBoneName skin mirror_wtReserve_bones[i] 0)
				append reserve_bone b.pos
			)
			for i = 1 to verts_count do	-- find corresponding reserve bone
			(
				p = getVert $ i
				v_b_dist[i] = #()
				for ii = 1 to reserve_bone.count do
				(
					append v_b_dist[i] (distance p reserve_bone[ii])
				)
				min = amin v_b_dist[i]
				index = findItem v_b_dist[i] min
				append vert_reserve mirror_wtReserve_bones[index]
			)
			
			-- no progressbar, will lost skin
			getWeights()
			for i = 1 to verts_count do	-- replace left side cross bone weights include right side vertexes
			(
				reserve_wt = 0
				cross_wts = 0	-- the sum of cross weights on left
				for ii = 1 to weights[i].count do
				(
					if findItem cross_bone_l weights[i][ii].i != 0 then
					(
						skinOps.SetVertexWeights skin i weights[i][ii].i 0
						cross_wts += weights[i][ii].w
					)
					else if weights[i][ii].i == vert_reserve[i] then
					(
						reserve_wt = weights[i][ii].w
					)
				)
				if reserve_wt + cross_wts > 0 then
				(
					skinOps.SetVertexWeights skin i vert_reserve[i] (reserve_wt+cross_wts)
				)
			)
			
			getWeights()
			for i = 1 to verts_count do	-- mirror all no cross weights
			(
				if findItem vtx_l i != 0 then	-- all left side vertexes
				(
					for ii = 1 to weights[i].count do	-- all affectting bones
					(
						if findItem cross_bone_r weights[i][ii].i == 0 then	-- zero all weights on the left except cross bones
						(
							skinOps.SetVertexWeights skin i weights[i][ii].i 0	-- zero it
						)
					)
					
					index = (findItem vtx_l i)	-- find index for the vertex on the right side
					r_wts = weights[vtx_r[index]]	-- get weights of the right one
					for ii = 1 to r_wts.count do	-- all affectting bones of right one
					(
						if findItem cross_bone_r r_wts[ii].i == 0 then		-- deal with them later
						(
							if (findItem bone_r r_wts[ii].i) != 0 then	 -- found bone on the right side
							(
								skinOps.SetVertexWeights skin i bone_l[(findItem bone_r r_wts[ii].i)] r_wts[ii].w	-- mirror it to left
							)
							else	-- middle bones
							(
								skinOps.SetVertexWeights skin i r_wts[ii].i r_wts[ii].w	-- r_wts[ii].i is the middle bone in this case
							)
						)
					)
				)
			)
			
			getWeights()
			for i = 1 to verts_count do	-- cross weights
			(
				bone_wts = #()
				for ii = 1 to weights[i].count do	-- get cross weights
				(
					if findItem cross_bone_r weights[i][ii].i != 0 then
					(
						b_wt = bone_id_wt()
						b_wt.i = weights[i][ii].i
						b_wt.w = weights[i][ii].w
						append bone_wts b_wt
					)
				)
				
				for ii = 1 to bone_wts.count do
				(
					l_bone = bone_l[findItem bone_r bone_wts[ii].i]	-- get cross bone on the left side

					index_l = findItem vtx_l i
					index_r = findItem vtx_r i
					
					wts = 0		-- the sum of the weights
					reserve_wt = 0
					
					if index_l != 0 then	-- vertex on the left awaiting to be mirrored
					(
						vert = vtx_r[index_l]
						skinOps.SetVertexWeights skin vert l_bone bone_wts[ii].w		-- paste cross weight to left side
						
						for b = 1 to weights[vert].count do
						(
							if weights[vert][b].i == vert_reserve[i] then
							(
								reserve_wt = skinOps.GetVertexWeight skin vert b
							)
						)
						for b = 1 to (skinOps.GetVertexWeightCount skin vert) do
						(
							wts += skinOps.GetVertexWeight skin vert b
						)
						if wts - 1 - reserve_wt > 0.001 then	-- check there is enough weight can be spared
						(
							format "Vertex ID:% Exceed:% (1st)\n" (vert-1) (wts-1-reserve_wt)
							skinOps.SetVertexWeights skin vert vert_reserve[i] 0
						)
						else
						(
							skinOps.SetVertexWeights skin vert vert_reserve[i] (reserve_wt - (wts-1))
						)
					)
					else if index_r != 0 then
					(
						vert = vtx_l[index_r]
						skinOps.SetVertexWeights skin vert l_bone bone_wts[ii].w		-- paste cross weight to left side
						
						for b = 1 to weights[vert].count do
						(
							if weights[vert][b].i == vert_reserve[i] then
							(
								reserve_wt = skinOps.GetVertexWeight skin vert b
							)
						)
						for b = 1 to (skinOps.GetVertexWeightCount skin vert) do
						(
							wts += skinOps.GetVertexWeight skin vert b
						)
						if wts - 1 - reserve_wt > 0.001 then	-- check there is enough weight can be spared
						(
							format "Vertex ID:% Exceed:% (1st)\n" (vert-1) (wts-1-reserve_wt)
							skinOps.SetVertexWeights skin vert vert_reserve[i] 0
						)
						else
						(
							skinOps.SetVertexWeights skin vert vert_reserve[i] (reserve_wt - (wts-1))
						)
					)
				)
			)
			
			getWeights()
			for i = 1 to verts_count do	-- middle vertexes
			(
				if findItem vtx_r i == 0 and findItem vtx_l i == 0 then
				(
					for b = 1 to weights[i].count do
					(
						if findItem bone_r weights[i][b].i != 0 then
						(
							wt_l = 0	-- origin weight on left
							reserve_wt = 0
							for j = 1 to weights[i].count do
							(
								if weights[i][j].i == bone_l[findItem bone_r weights[i][b].i] then
								(
									wt_l = weights[i][j].w
								)
								else if weights[i][j].i == vert_reserve[i] then
								(
									reserve_wt = skinOps.GetVertexWeight skin i j
								)
							)
							
							skinOps.SetVertexWeights skin \
							i \
							bone_l[findItem bone_r weights[i][b].i] \
							weights[i][b].w		-- weight of right
							
							wts = 0
							for b = 1 to (skinOps.GetVertexWeightCount skin i) do
							(
								wts += skinOps.GetVertexWeight skin i b
							)
							if wts - 1 - reserve_wt > 0.001 then	-- check there is enough weight left
							(
								format "Vertex ID:% Exceed:% (1st)\n" (i-1) (wts-1-reserve_wt)
								skinOps.SetVertexWeights skin i vert_reserve[i] 0
							)
							else
							(
								skinOps.SetVertexWeights skin i vert_reserve[i] (reserve_wt - (wts-1))
							)
						)
					)
				)
			)
			
			getWeights()
			ow_verts = #()
			for i = 1 to verts_count do	-- check normal
			(
				wts = 0
				for b = 1 to (skinOps.GetVertexWeightCount skin i) do
				(
					wts += skinOps.GetVertexWeight skin i b
				)
				if abs (wts-1) > 0.001 then
				(
					append ow_verts i
				)
			)
			format "-- % vertex(es) left unsolved.(1st)\n" ow_verts.count
			for i = 1 to ow_verts.count do
			(
				num = 1
				while abs ((getWeightSum ow_verts[i]) - 1) > 0.001 and num <= mirror_wtReserve_bones.count do
				(
					v_b_dist_copy = deepCopy v_b_dist[ow_verts[i]]
					sort v_b_dist_copy
					index = findItem v_b_dist[ow_verts[i]] v_b_dist_copy[num]
					wt_reserver = mirror_wtReserve_bones[index]
					
					reserve_wt = 0
					for b = 1 to weights[ow_verts[i]].count do
					(
						if weights[ow_verts[i]][b].i == wt_reserver then
						(
							reserve_wt = skinOps.GetVertexWeight skin ow_verts[i] b
						)
					)
					
					if (getWeightSum ow_verts[i]) - 1 - reserve_wt > 0.001 then	-- check there is enough weight left
					(
						format "Vertex ID:% Exceed:% (2nd_%/%)\n" (ow_verts[i]-1) ((getWeightSum ow_verts[i])-1-reserve_wt) num mirror_wtReserve_bones.count
						skinOps.SetVertexWeights skin ow_verts[i] wt_reserver 0
					)
					else
					(
						skinOps.SetVertexWeights skin ow_verts[i] wt_reserver (reserve_wt - ((getWeightSum ow_verts[i])-1))
					)
					
					num += 1
				)
			)
			
			getWeights()
			ow_verts = #()
			for i = 1 to verts_count do	-- 3rd attempt
			(
				wts = 0
				for b = 1 to (skinOps.GetVertexWeightCount skin i) do
				(
					wts += skinOps.GetVertexWeight skin i b
				)
				if abs (wts-1) > 0.001 then
				(
					append ow_verts i
				)
			)
			format "-- % vertex(es) left unsolved.(2nd)\n" ow_verts.count
			for i = 1 to ow_verts.count do
			(
				index_l = findItem vtx_l ow_verts[i]
				index_r = findItem vtx_r ow_verts[i]
				
				if index_l != 0 then
				(
					frozen_wts = 0
					wts = 0
					for b = 1 to weights[ow_verts[i]].count do
					(
						if findItem bone_r weights[ow_verts[i]][b].i == 0 then
						(
							frozen_wts += weights[ow_verts[i]][b].w
						)
						wts += weights[ow_verts[i]][b].w
					)
					free_wt = 1 - frozen_wts
					if free_wt > 0 then
					(
						ratio = #()
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_r weights[ow_verts[i]][b].i != 0 then
							(
								append ratio (weights[ow_verts[i]][b].w/(wts-frozen_wts))
							)
						)
						num = 1
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_r weights[ow_verts[i]][b].i != 0 then
							(
								skinOps.SetVertexWeights skin ow_verts[i] weights[ow_verts[i]][b].i (ratio[num]*free_wt)
								num += 1
							)
						)
					)
					else
					(
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_r weights[ow_verts[i]][b].i != 0 then
							(
								skinOps.SetVertexWeights skin ow_verts[i] weights[ow_verts[i]][b].i 0
							)
						)
					)
				)
				else if index_r != 0 then
				(
					frozen_wts = 0
					wts = 0
					for b = 1 to weights[ow_verts[i]].count do
					(
						if findItem bone_l weights[ow_verts[i]][b].i == 0 then
						(
							frozen_wts += weights[ow_verts[i]][b].w
						)
						wts += weights[ow_verts[i]][b].w
					)
					free_wt = 1 - frozen_wts
					if free_wt > 0 then
					(
						ratio = #()
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_l weights[ow_verts[i]][b].i != 0 then
							(
								append ratio (weights[ow_verts[i]][b].w/(wts-frozen_wts))
							)
						)
						num = 1
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_l weights[ow_verts[i]][b].i != 0 then
							(
								skinOps.SetVertexWeights skin ow_verts[i] weights[ow_verts[i]][b].i (ratio[num]*free_wt)
								num += 1
							)
						)
					)
					else
					(
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_l weights[ow_verts[i]][b].i != 0 then
							(
								skinOps.SetVertexWeights skin ow_verts[i] weights[ow_verts[i]][b].i 0
							)
						)
					)
				)
				else
				(
					frozen_wts = 0
					wts = 0
					for b = 1 to weights[ow_verts[i]].count do
					(
						if findItem bone_l weights[ow_verts[i]][b].i == 0 and findItem bone_r weights[ow_verts[i]][b].i == 0 then
						(
							frozen_wts += weights[ow_verts[i]][b].w
						)
						wts += weights[ow_verts[i]][b].w
					)
					free_wt = 1 - frozen_wts
					if free_wt > 0 then
					(
						ratio = #()
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_l weights[ow_verts[i]][b].i != 0 or findItem bone_r weights[ow_verts[i]][b].i != 0 then
							(
								append ratio (weights[ow_verts[i]][b].w/(wts-frozen_wts))
							)
						)
						num = 1
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_l weights[ow_verts[i]][b].i != 0 or findItem bone_r weights[ow_verts[i]][b].i != 0 then
							(
								skinOps.SetVertexWeights skin ow_verts[i] weights[ow_verts[i]][b].i (ratio[num]*free_wt)
								num += 1
							)
						)
					)
					else
					(
						for b = 1 to weights[ow_verts[i]].count do
						(
							if findItem bone_l weights[ow_verts[i]][b].i != 0 or findItem bone_r weights[ow_verts[i]][b].i != 0 then
							(
								skinOps.SetVertexWeights skin ow_verts[i] weights[ow_verts[i]][b].i 0
							)
						)
					)
				)
			)
			
			ow_verts = #()	-- final check
			for i = 1 to verts_count do
			(
				wts = 0
				for b = 1 to (skinOps.GetVertexWeightCount skin i) do
				(
					wts += skinOps.GetVertexWeight skin i b
				)
				if abs (wts-1) > 0.001 then
				(
					append ow_verts i
				)
			)
			format "-- % vertex(es) left unsolved.(3nd)\n" ow_verts.count
			for i = 1 to ow_verts.count do
			(
				print (ow_verts[i]-1)
				append check_verts ow_verts[i]
			)
			skinOps.SelectVertices skin check_verts
		)
	)
	
	
	-- functions
	fn getBoneIndexes skin =
	(
		bone_indexes = #()
		start = skinOps.GetSelectedBone skin
		append bone_indexes start
		skinOps.selectNextBone skin
		while (skinOps.GetSelectedBone skin) != start do
		(
			append bone_indexes (skinOps.GetSelectedBone skin)
			skinOps.selectNextBone skin
		)
	)
	
	fn getPairs skin =
	(
		count = bone_indexes.count
		
		skin_bone = #()
		for i = 1 to count do
		(
			append skin_bone (getnodebyname (skinOps.GetBoneName skin bone_indexes[i] 0))
		)
		bone_pairs = #()
		for l = 1 to count do
		(
			if skin_bone[l].pos.x > 0.001 then
			(
				for r = 1 to count do
				(
					if distance [-skin_bone[l].pos.x,skin_bone[l].pos.y,skin_bone[l].pos.z] skin_bone[r].pos < 0.005 and l != r then
					(
						p = pair()
						p.l = bone_indexes[l]
						p.r = bone_indexes[r]
						appendifunique bone_pairs p
					)
				)
			)
		)
		
		deviation = 0.05
		if vert_pairs.count == 0 then
		(
			vert_pairs = #()
			progressStart "Getting Vertex Pairs..."
			for i = 1 to verts_l.count do
			(
				progressUpdate (100.0 * i / verts_l.count)
				for l = 1 to verts_l[i].count do
				(
					for r = 1 to verts_r[i].count do
					(
						if distance [-verts_l[i][l].p.x,verts_l[i][l].p.y,verts_l[i][l].p.z] verts_r[i][r].p < deviation then
						(
							p = pair()
							p.l = verts_l[i][l]
							p.r = verts_r[i][r]
							appendifunique vert_pairs p
						)
					)
				)
			)
			progressEnd()
		)
		
		format "Pairs(Bone): %\n" bone_pairs.count
		format "Pairs(Vertex): %\n" vert_pairs.count
		
		selectVertexes()
	)
	
	fn selectVertexes =
	(
		vtxes = #()
		for i = 1 to vert_pairs.count do
		(
			append vtxes vert_pairs[i].l.i
		)
		skinOps.SelectVertices skin vtxes
	)
	
	fn saveData =
	(
		str_s = stringStream ""
		for i = 1 to vert_pairs.count do
		(
			append str_s ((vert_pairs[i].l.i as string) as stringStream)
			append str_s (" " as stringStream)
			append str_s ((vert_pairs[i].r.i as string) as stringStream)
			append str_s ("\n" as stringStream)
		)
		f_path = (getDir #scripts) + "\\temp_pairs.txt"
		if f_path != undefined then
		(
			f = createFile f_path
			format (str_s as string) to:f
			close f
			free f
		)
		
		format "Saved to \"%\"\n" f_path
	)
	
	fn getWeights =
	(
		skin.clearZeroLimit = 0
		skinOps.RemoveZeroWeights skin
		
		weights = #()
		for i = 1 to verts_count do
		(
			weights[i] = #()
			for b = 1 to (skinOps.GetVertexWeightCount skin i) do
			(
				w = wt()
				w.i = skinOps.GetVertexWeightBoneID skin i b
				w.n = skinOps.GetBoneName skin w.i 0
				w.w = skinOps.GetVertexWeight skin i b
				append weights[i] w
			)
		)
	)
	
	fn getWeightSum index =
	(
		wts = 0
		for b = 1 to (skinOps.GetVertexWeightCount skin index) do
		(
			wts += skinOps.GetVertexWeight skin index b
		)
		
		wts
	)
	
	
	-- events
	on wtAssign_ro open do
	(
		if $ != undefined and $.modifiers != undefined and $.modifiers[#skin] != undefined then
		(
			skin = $.modifiers[#skin]
		)
		
		verts_count = getNumVerts $
		format "Vertex count: %\n" verts_count
	)
	
	on wtAssign_ro close do
	(
		unregisterRedrawViewsCallback GW_display
		GW_display = undefined
	)
)

rollout select_dialog_ro "Select" width:400 height:320
(
	local skin = undefined
	
	local middle_bones = #()
	
	multiListBox mb_cross "Cross Weighted Bones" height:10
	multiListBox mb_reserve "Weight Reserve Bones" height:4
	
	button btn_done "OK" \
	width:100 height:30
	on btn_done pressed  do
	(
		mirror_wtCross_bones = #()
		mirror_wtReserve_bones = #()
		for i = 1 to mb_cross.selection.count do
		(
			if mb_cross.selection[i] then
			(
				append mirror_wtCross_bones wtAssign_ro.bone_pairs[i]
			)
		)
		for i = 1 to mb_reserve.selection.count do
		(
			if mb_reserve.selection[i] then
			(
				append mirror_wtReserve_bones middle_bones[i]
				
			)
		)
		
		if mirror_wtCross_bones.count >= 1 and mirror_wtReserve_bones.count >= 1 then
		(
			wtAssign_ro.btn_operate.enabled = true
			closeRolloutFloater select_dialog_rf
		)
	)
	
	on select_dialog_ro open do
	(
		if $ != undefined and $.modifiers != undefined and $.modifiers[#skin] != undefined then
		(
			skin = $.modifiers[#skin]
		)
		
		list = #()
		idx_list = #()
		for i = 1 to wtAssign_ro.bone_pairs.count do
		(
			str = ""
			str += skinOps.GetBoneName skin wtAssign_ro.bone_pairs[i].r 0
			str += "<->"
			str += skinOps.GetBoneName skin wtAssign_ro.bone_pairs[i].l 0
			append list str
			append idx_list wtAssign_ro.bone_pairs[i].r
			append idx_list wtAssign_ro.bone_pairs[i].l
		)
		mb_cross.items = list
		
		list = #()
		middle_bones = #()
		for i = 1 to wtAssign_ro.bone_indexes.count do
		(
			if finditem idx_list wtAssign_ro.bone_indexes[i] == 0 then
			(
				str = skinOps.GetBoneName skin wtAssign_ro.bone_indexes[i] 0
				append list str
				append middle_bones i
			)
		)
		mb_reserve.items = list
	)
)

fn GW_display =
(
	if wtAssign_ro != undefined then
	(
		for i = 1 to wtAssign_ro.vert_pairs.count do
		(
			if wtAssign_ro.rdo_display.state == 2 or wtAssign_ro.rdo_display.state == 4 then
			(
				gw.Polyline #(wtAssign_ro.vert_pairs[i].l.p,wtAssign_ro.vert_pairs[i].r.p) \
				false
				gw.setColor #line orange
			)
			if wtAssign_ro.rdo_display.state == 3 or wtAssign_ro.rdo_display.state == 4 then
			(
				gw.Marker wtAssign_ro.vert_pairs[i].l.p #circle color:red
				gw.Marker wtAssign_ro.vert_pairs[i].r.p #hollowBox color:green
			)
		)
	)
)

if wtAssign_rf != undefined do closeRolloutFloater wtAssign_rf
if select_dialog_rf != undefined do closeRolloutFloater select_dialog_rf
wtAssign_rf = newRolloutFloater "" 250 330 20 160
addRollout wtAssign_ro	wtAssign_rf
