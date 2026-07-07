return {
	"harukikuri/todoage.nvim",
	opts = {
		format = function(age_days)
			local years = math.floor(age_days / 365)
			local remaining = age_days % 365
			local months = math.floor(remaining / 30)
			local days = remaining % 30
			local parts = {}

			if years > 0 then
				table.insert(parts, years .. "y")
			end
			if months > 0 then
				table.insert(parts, months .. "mo")
			end
			if days > 0 or #parts == 0 then
				table.insert(parts, days .. "d")
			end

			return "(" .. table.concat(parts, " ") .. ")"
		end,
	},
}
