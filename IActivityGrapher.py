#!/usr/bin/env python3
import cairo, colorsys, collections, dateutil.parser, random, sys

class Activity:
    def __init__(self, start_time, end_time, description):
        self.start_time = start_time
        self.end_time = end_time
        self.description = description

    @classmethod
    def from_iactivity_line(cls, iactivity_line):
        raw_start_time, raw_end_time, description = iactivity_line.split(" ", 2)

        if raw_end_time == "__ongoing__":
            return

        start_time = dateutil.parser.parse(raw_start_time)
        end_time = dateutil.parser.parse(raw_end_time)

        return cls(start_time, end_time, description.rstrip())

    @classmethod
    def list_from_iactivity_file(cls, iactivity_file):
        activity_list = []

        for line in iactivity_file:
           act = Activity.from_iactivity_line(line)
           if act is not None:
               activity_list.append(act)

        return activity_list

    def overlap(self, other):
        if ((self.start_time <= self.end_time < other.start_time <= other.end_time)
                or (other.start_time <= other.end_time < self.start_time <= self.end_time)):
            return False
        else:
            return True

    def __lt__(self, other):
        if self.start_time < other.start_time:
            return True
        elif self.start_time == other.start_time:
            if self.end_time < other.end_time:
                return True
            else:
                return False
        else:
            return False

    def __le__(self, other):
        return (self < other) or (self == other)

    def __gt__(self, other):
        return not ((self < other) or (self == other))

    def __ge__(self, other):
        return (self > other) or (self == other)

    def __eq__(self, other):
        if (self.start_time == other.start_time) and (self.end_time == other.end_time):
            return True
        else:
            return False

class ActivityLanes(list):
    def __init__(self, activity_list):
        sorted_activities = collections.deque(sorted(activity_list))
        deferred_activities = collections.deque()
        self.append([])
        self.min_time, self.max_time = None, None

        while len(sorted_activities) + len(deferred_activities) > 0:
            if len(sorted_activities) == 0:  # next lane
                self.append([])
                sorted_activities = deferred_activities
                deferred_activities = collections.deque()

            next_activity = sorted_activities.popleft()

            if (self.min_time == None) or (next_activity.start_time < self.min_time):
                self.min_time = next_activity.start_time

            if (self.max_time == None) or (next_activity.end_time > self.max_time):
                self.max_time = next_activity.end_time

            if self[-1] == [] or not self[-1][-1].overlap(next_activity):
                self[-1].append(next_activity)
            else:
                deferred_activities.append(next_activity)

    def render(self, filename):
        num_blocks = sum(map(len, self))
        blocks = []

        width = round(120 * ((self.max_time - self.min_time).total_seconds() / (60 * 60)))
        height = (30 * len(self)) + (5 * (len(self) - 1)) + (35 * num_blocks) + 5

        cairo_canvas = cairo.ImageSurface(cairo.FORMAT_ARGB32, width, height)
        cairo_context = cairo.Context(cairo_canvas)

        for lane_num, lane in enumerate(self):
            for activity in lane:
                block_hls = ((len(blocks) / num_blocks), 0.6 - (random.random() / 4), 0.8 - (random.random() / 4))
                block_rgb = colorsys.hls_to_rgb(*block_hls)
                cairo_context.set_source_rgb(*block_rgb)

                blocks.append((block_rgb, activity.description))

                block_x = round(120 * ((activity.start_time - self.min_time).total_seconds() / (60 * 60)))
                block_y = 35 * lane_num
                block_width = max(round(120 * ((activity.end_time - activity.start_time).total_seconds() / (60 * 60))), 1)
                block_height = 30

                cairo_context.rectangle(block_x, block_y, block_width, block_height)
                cairo_context.fill()

#                cairo_context.set_source_rgb(0, 0, 0)
#                cairo_context.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
#                        cairo.FONT_WEIGHT_NORMAL)
#                cairo_context.set_font_size(10)
#                cairo_context.move_to(block_x + 10, block_y + 10)
#                cairo_context.show_text(activity.description)

        for block_num, ((r, g, b), description) in enumerate(blocks):
            block_x = 10
            block_y = (35 * len(self)) + (35 * block_num) + 5

            cairo_context.set_source_rgb(r, g, b)
            cairo_context.rectangle(block_x, block_y, 20, 20)
            cairo_context.fill()

            cairo_context.set_source_rgb(0, 0, 0)
            cairo_context.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
                    cairo.FONT_WEIGHT_NORMAL)
            cairo_context.set_font_size(20)
            cairo_context.move_to(block_x + 30, block_y + 15)
            cairo_context.show_text(description)

        cairo_canvas.write_to_png(filename)
        print("Wrote {}!".format(filename))

def main():
    with open("/home/bitshift/.Iactivities", "r") as activity_file:
        activities = Activity.list_from_iactivity_file(activity_file)
        lanes = ActivityLanes(activities)

        lanes.render((sys.argv[1:2] or ["IActivityGraph.png"])[0])

if __name__ == "__main__":
    main()
